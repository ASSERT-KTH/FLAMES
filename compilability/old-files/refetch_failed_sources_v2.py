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

# ---------- robust SourceCode unboxing ----------
def _json_load_maybe(s: str):
    try:
        return True, json.loads(s)
    except Exception:
        return False, None

def unbox_sourcecode(source_str: str):
    """Try really hard to turn SourceCode into a standard-json-like dict.
    Returns (src_obj_dict_or_None, last_string_version)
    - If we can parse a dict (with or without 'sources'), return it.
    - Otherwise return None plus the best string representation (for single-file write).
    """
    if not isinstance(source_str, str):
        return None, ""

    s = source_str.strip()
    if not s:
        return None, ""

    # Always keep a copy of the last string seen
    last_s = s

    # Strategy A: direct parse
    ok, obj = _json_load_maybe(s)
    if ok and isinstance(obj, dict):
        return obj, last_s
    if ok and isinstance(obj, str):
        last_s = obj
        s = obj  # fall through to attempt again

    # Strategy B: double-wrapped braces or quoted object
    if (s.startswith("{{") and s.endswith("}}")) or (s.startswith('"{') and s.endswith('}"')):
        inner = s[1:-1]
        ok, obj = _json_load_maybe(inner)
        if ok and isinstance(obj, dict):
            return obj, last_s
        if ok and isinstance(obj, str):
            last_s = obj
            s = obj

    # Strategy C: repeated decoding (some responses are JSON-encoded strings of JSON)
    for _ in range(3):
        ok, obj = _json_load_maybe(s)
        if ok and isinstance(obj, dict):
            return obj, last_s
        if ok and isinstance(obj, str):
            last_s = obj
            s = obj
            continue
        break

    # Strategy D: trim stray quotes/backticks
    t = s.strip().strip("`").strip("'").strip('"').strip()
    if t and t != s:
        ok, obj = _json_load_maybe(t)
        if ok and isinstance(obj, dict):
            return obj, last_s

    # Give up; treat as single-file string
    return None, last_s

SAFE_CHARS_RE = re.compile(r"[^0-9A-Za-z._/\-]+")


def _safe_relpath(p: str, default_name: str) -> Path:
    """Convert any path to a safe *relative* path."""
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
    """Write sources from a standard-json-like object."""
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
    ap = argparse.ArgumentParser(description="Refetch sources for failed addresses with aggressive unboxing and full payload dumps.")
    ap.add_argument("--in", dest="in_csv", required=True, help="failed_compilations.csv or refetch_zero_files.csv")
    ap.add_argument("--out", dest="out_csv", default="refetched_index_v2.csv", help="Index CSV of refetch results")
    ap.add_argument("--projects-dir", default="./contracts", help="Where to write <address>/")
    ap.add_argument("--logs-dir", default="./failed_logs", help="Where to write per-address notes")
    ap.add_argument("--overwrite", action="store_true", help="If set, delete existing address folders before writing")
    ap.add_argument("--follow-proxy", action="store_true", help="Fetch implementation source when Proxy=1")
    ap.add_argument("--force-single", action="store_true", help="If set, write Flattened.sol from SourceCode string when JSON parse yields 0 files")
    ap.add_argument("--only-address", default=None, help="Process only this address (case-insensitive), even if not in CSV")
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

    if args.only_address:
        addr = args.only_address.strip().lower()
        sub = df[df["contract_address"].astype(str).str.lower() == addr]
        if sub.empty:
            sub = pd.DataFrame([{"original_idx": -1, "label": "", "contract_address": addr}])
        df = sub

    if args.limit is not None:
        df = df.head(args.limit).copy()

    root = Path(args.projects_dir)
    logs_root = Path(args.logs_dir)
    _ensure_dir(root); _ensure_dir(logs_root)

    results = []
    iterator = df.itertuples(index=False)
    if _HAS_TQDM:
        iterator = tqdm(iterator, total=len(df), desc="RefetchV2", unit="addr")

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
            "payload_saved": False,
            "sourcecode_raw_saved": False,
            "parsed_sourcecode_saved": False,
        }

        try:
            time.sleep(args.rate_delay)
            logging.info(f"[{i}/{len(df)}] Fetching {addr} ...")
            info = fetch_etherscan_sources(addr, api_key, args.timeout, args.chain_id)

            default_name = f"{(info.get('ContractName') or 'Contract').strip() or 'Contract'}.sol"

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
                except Exception as e:
                    logging.warning(f"[{i}/{len(df)}] Failed to fetch implementation {impl_addr}: {e}")

            # Prepare project folder
            if args.overwrite and proj.exists():
                shutil.rmtree(proj, ignore_errors=True)
            _ensure_dir(proj)

            # Save raw payload and raw SourceCode string verbatim
            (proj / "raw_payload.json").write_text(json.dumps(chosen_info, indent=2))
            rec["payload_saved"] = True

            src_str = (chosen_info.get("SourceCode") or "")
            (proj / "sourcecode_raw.txt").write_text(src_str if isinstance(src_str, str) else str(src_str))
            rec["sourcecode_raw_saved"] = True

            # Aggressive unboxing
            src_obj, last_str = unbox_sourcecode(src_str)

            if isinstance(src_obj, dict):
                (proj / "parsed_sourcecode.json").write_text(json.dumps(src_obj, indent=2))
                rec["parsed_sourcecode_saved"] = True

            # Persist sources
            paths_map: Dict[str,str] = {}
            if isinstance(src_obj, dict):
                n = write_sources_from_obj(proj, src_obj, default_name, paths_map)
            else:
                n = 0

            # If no files from JSON, optionally force single-file write from string
            if n == 0 and args.force_single and isinstance(last_str, str) and last_str.strip():
                n = write_single_file(proj, last_str, default_name, paths_map)

            # Save the mapping for transparency
            (proj / "paths_map.json").write_text(json.dumps(paths_map, indent=2))

            rec["n_files"] = int(n)
            rec["fetch_ok"] = True
            rec["compiler_version"] = _extract_semver(chosen_info.get("CompilerVersion", "") or "") or ""
            rec["language"] = (chosen_info.get("Language") or "").strip()

            if n == 0:
                rec["message"] = "No files written (after unboxing); see sourcecode_raw.txt / parsed_sourcecode.json"
                logging.warning(f"[{i}/{len(df)}] {addr} → wrote 0 files (forced={args.force_single})")
            else:
                logging.info(f"[{i}/{len(df)}] {addr} → wrote {n} files to {proj}")

        except Exception as e:
            rec["message"] = f"RefetchV2 error: {e}"
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
