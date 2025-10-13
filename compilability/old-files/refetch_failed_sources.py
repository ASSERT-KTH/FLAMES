#!/usr/bin/env python3
import argparse
import json
import logging
import os
import re
import sys
import time
import shutil
import hashlib
from pathlib import Path
from typing import Dict, Tuple, Optional, List

import pandas as pd
import requests
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

try:
    from rich.logging import RichHandler
    _HAS_RICH = True
except ImportError:
    _HAS_RICH = False

try:
    from tqdm import tqdm
    _HAS_TQDM = True
except ImportError:
    _HAS_TQDM = False

ETHERSCAN_API_URL_V2 = "https://api.etherscan.io/v2/api"
DEFAULT_RATE_DELAY = 0.22  # ~5 req/sec

class EtherscanError(Exception):
    pass

def setup_logging(level: str, log_file: Optional[str]) -> None:
    lvl = getattr(logging, level.upper(), logging.INFO)
    handlers: List[logging.Handler] = []
    if _HAS_RICH:
        handlers.append(RichHandler(rich_tracebacks=False, show_time=False))
    else:
        ch = logging.StreamHandler(sys.stdout)
        ch.setFormatter(logging.Formatter("%(levelname)s %(message)s"))
        handlers.append(ch)
    if log_file:
        fh = logging.FileHandler(log_file, encoding="utf-8")
        fh.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s", "%Y-%m-%d %H:%M:%S"))
        handlers.append(fh)
    logging.basicConfig(level=lvl, handlers=handlers)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("requests").setLevel(logging.WARNING)

def _ensure_dir(p: Path):
    p.mkdir(parents=True, exist_ok=True)

def _extract_semver(compiler_version: str) -> Optional[str]:
    if not compiler_version:
        return None
    m = re.search(r"(\d+\.\d+\.\d+)", compiler_version)
    return m.group(1) if m else None

@retry(
    retry=retry_if_exception_type((requests.RequestException, EtherscanError)),
    wait=wait_exponential(multiplier=1, min=1, max=16),
    stop=stop_after_attempt(5),
)
def fetch_etherscan_sources(address: str, api_key: str, timeout: float, chain_id: int) -> Dict:
    params = {
        "module": "contract",
        "action": "getsourcecode",
        "address": address,
        "chainid": chain_id,
        "apikey": api_key,
    }
    r = requests.get(ETHERSCAN_API_URL_V2, params=params, timeout=timeout)
    if r.status_code != 200:
        raise requests.RequestException(f"HTTP {r.status_code}: {r.text}")
    payload = r.json()
    if payload.get("status") != "1" or not payload.get("result"):
        raise EtherscanError(f"Etherscan V2 error for {address} (chainid={chain_id}): {payload}")
    return payload["result"][0]

def _maybe_parse_sourcecode(source_str: str) -> Optional[Dict]:
    """
    Try to parse SourceCode into a JSON object:
     - raw standard-json input (dict)
     - double-wrapped { ... } → try s and s[1:-1]
     - returns dict if parseable, else None (single-file case)
    """
    if not source_str:
        return None
    s = source_str.strip()
    if not ((s.startswith("{") and s.endswith("}")) or (s.startswith("{{") and s.endswith("}}"))):
        return None
    for cand in (s, s[1:-1]):
        try:
            obj = json.loads(cand)
            if isinstance(obj, dict):
                return obj
        except Exception:
            pass
    return None

SAFE_CHARS_RE = re.compile(r"[^0-9A-Za-z._/\-]+")

def _safe_relpath(p: str, default_name: str) -> Path:
    """
    Convert any path to a safe *relative* path:
      - strip URL schemes, drive letters, leading '/'
      - remove '.' and '..'
      - sanitize odd chars
      - ensure .sol filename at end
    """
    if not p:
        return Path(default_name)

    s = str(p).strip().replace("\\", "/")
    s = re.sub(r"^[a-zA-Z][a-zA-Z0-9+.\-]*://", "", s)  # strip scheme
    s = re.sub(r"^[A-Za-z]:/", "", s)                   # strip windows drive
    s = s.lstrip("/")                                   # drop leading slash

    parts = []
    for seg in s.split("/"):
        if not seg or seg in (".", ".."):
            continue
        seg = SAFE_CHARS_RE.sub("_", seg)
        parts.append(seg)

    if not parts:
        parts = [default_name]
    rel = Path(*parts)
    if rel.suffix.lower() != ".sol":
        rel = rel / default_name
    return rel

def _unique_path(base: Path, rel: Path) -> Path:
    target = base / rel
    if not target.exists():
        return target
    stem, suf = target.stem, target.suffix or ".sol"
    h = hashlib.sha1(str(target).encode("utf-8")).hexdigest()[:8]
    return target.with_name(f"{stem}-{h}{suf}")

def write_sources_from_obj(project_dir: Path, src_obj: Dict, default_name: str, paths_map: Dict[str, str]) -> int:
    """
    src_obj is a standard-json dict. We support:
      - sources: { "path.sol": {"content": "..."} }
      - sources: { "path.sol": "..." }   (rare but seen)
    """
    written = 0
    sources = src_obj.get("sources", {})
    if not isinstance(sources, dict):
        return 0
    for raw_path, meta in sources.items():
        content = None
        if isinstance(meta, dict):
            content = meta.get("content")
        elif isinstance(meta, str):
            content = meta
        if not isinstance(content, str) or len(content.strip()) == 0:
            continue
        rel = _safe_relpath(str(raw_path), default_name=default_name)
        fpath = _unique_path(project_dir, rel)
        _ensure_dir(fpath.parent)
        fpath.write_text(content)
        written += 1
        paths_map[str(raw_path)] = str(rel)
    return written

def write_single_file(project_dir: Path, content: str, default_name: str, paths_map: Dict[str, str]) -> int:
    if not isinstance(content, str) or len(content.strip()) == 0:
        return 0
    rel = _safe_relpath(default_name, default_name=default_name)
    fpath = _unique_path(project_dir, rel)
    _ensure_dir(fpath.parent)
    fpath.write_text(content)
    paths_map[default_name] = str(rel)
    return 1

def clear_dir_if_overwrite(path: Path, overwrite: bool):
    if overwrite and path.exists():
        shutil.rmtree(path, ignore_errors=True)

def main():
    ap = argparse.ArgumentParser(description="Refetch sources for failed addresses (follows proxies, robust parsing).")
    ap.add_argument("--in", dest="in_csv", required=True, help="failed_compilations.csv")
    ap.add_argument("--out", dest="out_csv", default="refetched_index.csv", help="Index CSV of refetch results")
    ap.add_argument("--projects-dir", default="./contracts", help="Where to write <address>/")
    ap.add_argument("--logs-dir", default="./failed_logs", help="Where to write per-address notes")
    ap.add_argument("--overwrite", action="store_true", help="If set, delete existing address folders before writing")
    ap.add_argument("--follow-proxy", action="store_true", help="Fetch implementation source when Proxy=1")
    ap.add_argument("--rate-delay", type=float, default=DEFAULT_RATE_DELAY, help="Sleep between API calls (s)")
    ap.add_argument("--timeout", type=float, default=30.0, help="HTTP timeout seconds")
    ap.add_argument("--chain-id", type=int, default=1, help="Etherscan chain id (1=Ethereum)")
    ap.add_argument("--limit", type=int, default=None, help="Optional limit for quick tests")
    ap.add_argument("--checkpoint-every", type=int, default=50, help="Write partial CSV every N rows")
    ap.add_argument("--log-level", default="INFO", choices=["DEBUG","INFO","WARNING","ERROR"])
    ap.add_argument("--log-file", default=None)
    args = ap.parse_args()

    setup_logging(args.log_level, args.log_file)

    api_key = os.environ.get("ETHERSCAN_API_KEY")
    if not api_key:
        logging.error("ETHERSCAN_API_KEY not set.")
        sys.exit(1)

    df = pd.read_csv(args.in_csv)
    needed = {"original_idx","label","contract_address"}
    if not needed.issubset(df.columns):
        logging.error(f"Input CSV must have columns: {needed}")
        sys.exit(1)

    if args.limit is not None:
        df = df.head(args.limit).copy()

    root = Path(args.projects_dir)
    logs_root = Path(args.logs_dir)
    _ensure_dir(root); _ensure_dir(logs_root)

    results = []
    iterator = df.itertuples(index=False)
    if _HAS_TQDM:
        iterator = tqdm(iterator, total=len(df), desc="Refetch", unit="addr")

    for i, row in enumerate(iterator, start=1):
        orig_idx = int(getattr(row, "original_idx"))
        label = str(getattr(row, "label"))
        addr = str(getattr(row, "contract_address")).strip().lower()
        proj = root / addr

        rec = {
            "original_idx": orig_idx,
            "label": label,
            "contract_address": addr,
            "fetch_ok": False,
            "used_implementation": False,
            "implementation_address": "",
            "compiler_version": "",
            "language": "",
            "n_files": 0,
            "message": "",
        }

        note_lines = [
            f"original_idx={orig_idx}",
            f"label={label}",
            f"address={addr}",
        ]

        try:
            time.sleep(args.rate_delay)
            logging.info(f"[{i}/{len(df)}] Fetching {addr} ...")
            info = fetch_etherscan_sources(addr, api_key, args.timeout, args.chain_id)

            # Save the raw payload for the proxy/primary address
            paths_map: Dict[str,str] = {}
            default_name = f"{(info.get('ContractName') or 'Contract').strip() or 'Contract'}.sol"

            # Follow proxy if requested
            impl_addr = (info.get("Implementation") or "").strip().lower()
            is_proxy = str(info.get("Proxy", "")).strip() == "1"
            chosen_info = info
            if args.follow_proxy and is_proxy and impl_addr:
                time.sleep(args.rate_delay)
                logging.info(f"[{i}/{len(df)}] {addr} is a proxy → fetching implementation {impl_addr}")
                try:
                    impl_info = fetch_etherscan_sources(impl_addr, api_key, args.timeout, args.chain_id)
                    chosen_info = impl_info
                    rec["used_implementation"] = True
                    rec["implementation_address"] = impl_addr
                    # also keep a copy of proxy meta inside the folder
                except Exception as e:
                    logging.warning(f"[{i}/{len(df)}] Failed to fetch implementation {impl_addr}: {e}")

            # Prepare project folder
            clear_dir_if_overwrite(proj, args.overwrite)
            _ensure_dir(proj)

            # Persist raw payloads for transparency
            (proj / "raw_payload.json").write_text(json.dumps(chosen_info, indent=2))
            if chosen_info is not info:
                (proj / "raw_payload.proxy.json").write_text(json.dumps(info, indent=2))

            rec["compiler_version"] = _extract_semver(chosen_info.get("CompilerVersion", "") or "") or ""
            rec["language"] = (chosen_info.get("Language") or "").strip()

            # Parse and write sources
            src_str = chosen_info.get("SourceCode", "") or ""
            src_obj = _maybe_parse_sourcecode(src_str)

            if isinstance(src_obj, dict):
                # Save the standard JSON as we used it
                (proj / "standard_input.json").write_text(json.dumps(src_obj, indent=2))
                n = write_sources_from_obj(proj, src_obj, default_name, paths_map)
            else:
                n = write_single_file(proj, src_str, default_name, paths_map)

            # Persist paths map for debugging
            (proj / "paths_map.json").write_text(json.dumps(paths_map, indent=2))

            rec["n_files"] = n
            rec["fetch_ok"] = True
            if n == 0:
                rec["message"] = "No files written (empty/malformed SourceCode)"
                logging.warning(f"[{i}/{len(df)}] {addr} → wrote 0 files")
            else:
                logging.info(f"[{i}/{len(df)}] {addr} → wrote {n} files to {proj}")

        except Exception as e:
            rec["message"] = f"Refetch error: {e}"
            logging.exception(f"[{i}/{len(df)}] {addr} → ERROR")

        results.append(rec)

        if args.checkpoint_every and (i % args.checkpoint_every == 0):
            tmp = f"{args.out_csv}.part"
            pd.DataFrame(results).to_csv(tmp, index=False)
            logging.info(f"[checkpoint] wrote {tmp}")

    out = pd.DataFrame(results)
    out.to_csv(args.out_csv, index=False)
    logging.info(f"[OK] Refetched {len(out)} rows → {args.out_csv}")

if __name__ == "__main__":
    main()
