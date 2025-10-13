#!/usr/bin/env python3
import argparse
import json
import logging
import os
import re
import sys
import time
import hashlib
from pathlib import Path
from typing import Dict, Tuple, Optional, List

import pandas as pd
import requests
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

from solcx import (
    install_solc,
    set_solc_version,
    compile_source,
    compile_standard,
    get_installed_solc_versions,
)

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

# ---- V2 endpoint (per Etherscan migration guide) ----
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
    """
    Etherscan API V2: module=contract&action=getsourcecode&address=...&chainid=1
    """
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

def _maybe_fix_wrapped_json(s: str) -> Optional[Dict]:
    if not s:
        return None
    s = s.strip()
    if (s.startswith("{") and s.endswith("}")) or (s.startswith("{{") and s.endswith("}}")):
        for candidate in (s, s[1:-1]):  # try raw and "unwrapped"
            try:
                return json.loads(candidate)
            except Exception:
                pass
    return None

# ---------- NEW: path safety helpers ----------
SAFE_CHARS_RE = re.compile(r"[^0-9A-Za-z._/\-]+")

def _safe_relpath(p: str, default_name: str = "Contract.sol") -> Path:
    """
    Convert any arbitrary path to a safe *relative* path under the project dir.
    - strips schemes (ipfs://, https://), drive letters, leading slashes
    - removes '.' and '..'
    - sanitizes weird chars
    - ensures a .sol filename at the end
    """
    if not p:
        return Path(default_name)

    s = str(p).strip().replace("\\", "/")
    s = re.sub(r"^[a-zA-Z][a-zA-Z0-9+.\-]*://", "", s)  # strip URL scheme
    s = re.sub(r"^[A-Za-z]:/", "", s)                   # strip Windows drive
    s = s.lstrip("/")                                   # drop leading slash (no absolute)

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
    """
    If base/rel exists, append a short hash to avoid collisions.
    """
    target = base / rel
    if not target.exists():
        return target
    stem, suf = target.stem, target.suffix or ".sol"
    h = hashlib.sha1(str(target).encode("utf-8")).hexdigest()[:8]
    return target.with_name(f"{stem}-{h}{suf}")

def _has_nonempty_sol(project_dir: Path) -> bool:
    for f in project_dir.rglob("*.sol"):
        try:
            if f.stat().st_size > 0:
                return True
        except OSError:
            pass
    return False
# ----------------------------------------------

def write_sources_to_disk(base_dir: Path, address: str, src_obj: Dict, single_file: Optional[str], contract_name: str) -> Tuple[int, Path]:
    """
    Writes either multi-file 'sources' (from JSON) or a single .sol file to disk.
    - All paths are sanitized to be relative to the project directory.
    - Skips empty contents.
    - If a 'source key' looks like a directory, we store it as <that>/<Contract.sol>.
    Returns (n_files_written, project_dir).
    """
    proj_dir = base_dir / address.lower()
    _ensure_dir(proj_dir)

    written = 0
    default_name = f"{(contract_name or 'Contract').strip() or 'Contract'}.sol"

    if src_obj and "sources" in src_obj and isinstance(src_obj["sources"], dict):
        for raw_path, meta in src_obj["sources"].items():
            content = (meta or {}).get("content")
            if not isinstance(content, str) or len(content.strip()) == 0:
                continue
            rel = _safe_relpath(str(raw_path), default_name=default_name)
            fpath = _unique_path(proj_dir, rel)
            _ensure_dir(fpath.parent)
            fpath.write_text(content)
            written += 1

        # Persist the full standard JSON we used (optional but handy)
        (proj_dir / "standard_input.json").write_text(json.dumps(src_obj, indent=2))
        return written, proj_dir

    # Fallback: single-file
    if isinstance(single_file, str) and len(single_file.strip()) > 0:
        rel = _safe_relpath(default_name, default_name=default_name)
        fpath = _unique_path(proj_dir, rel)
        _ensure_dir(fpath.parent)
        fpath.write_text(single_file)
        written = 1

    return written, proj_dir

def try_compile(project_dir: Path, src_obj: Optional[Dict], compiler_version: Optional[str], opt_used: Optional[str], runs: Optional[str]) -> Tuple[bool, str]:
    # Guard: no non-empty Solidity sources
    if not _has_nonempty_sol(project_dir):
        return False, "No non-empty Solidity sources to compile"

    if not compiler_version:
        return False, "No compiler version reported by Etherscan"

    if compiler_version not in [str(v) for v in get_installed_solc_versions()]:
        try:
            logging.info(f"Installing solc {compiler_version} ...")
            install_solc(compiler_version)
        except Exception as e:
            return False, f"Failed to install solc {compiler_version}: {e}"
    try:
        set_solc_version(compiler_version)
    except Exception as e:
        return False, f"Failed to set solc {compiler_version}: {e}"
    try:
        if src_obj and "sources" in src_obj:
            std = {
                "language": src_obj.get("language", "Solidity"),
                "sources": src_obj["sources"],
                "settings": src_obj.get("settings", {}),
            }
            if "optimizer" not in std["settings"]:
                std["settings"]["optimizer"] = {
                    "enabled": str(opt_used) == "1",
                    "runs": int(runs) if (runs and str(runs).isdigit()) else 200,
                }
            _ = compile_standard(std)
        else:
            sols = list(project_dir.rglob("*.sol"))
            if not sols:
                return False, "No .sol files found to compile"
            _ = compile_source(sols[0].read_text())
        return True, "Compiled OK"
    except Exception as e:
        return False, f"Compilation failed: {e}"

def _checkpoint(rows: List[dict], out_csv: str) -> None:
    tmp = f"{out_csv}.part"
    pd.DataFrame(rows).to_csv(tmp, index=False)
    logging.info(f"[checkpoint] Wrote partial results → {tmp}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="in_csv", required=True, help="Input CSV (from build_disl_subset.py)")
    ap.add_argument("--out", dest="out_csv", required=True, help="Output CSV with fetch/compile flags")
    ap.add_argument("--outdir", dest="out_dir", default="./contracts", help="Base directory to write projects")
    # QoL flags
    ap.add_argument("--log-level", default="INFO", choices=["DEBUG", "INFO", "WARNING", "ERROR"])
    ap.add_argument("--log-file", default=None, help="Optional log file path")
    ap.add_argument("--checkpoint-every", type=int, default=25, help="Write partial CSV every N rows")
    ap.add_argument("--skip-existing", action="store_true", help="Skip if project dir already has .sol files")
    ap.add_argument("--limit", type=int, default=None, help="Process at most N rows")
    ap.add_argument("--fail-fast", action="store_true", help="Abort on first error")
    ap.add_argument("--rate-delay", type=float, default=DEFAULT_RATE_DELAY, help="Seconds to sleep between Etherscan calls")
    ap.add_argument("--timeout", type=float, default=30.0, help="HTTP timeout seconds")
    ap.add_argument("--dry-run", action="store_true", help="Skip network/compile, just structure the output")
    # V2 multichain
    ap.add_argument("--chain-id", type=int, default=1, help="Etherscan V2 chain id (1=Ethereum mainnet)")

    args = ap.parse_args()
    setup_logging(args.log_level, args.log_file)

    api_key = os.environ.get("ETHERSCAN_API_KEY")
    if not args.dry_run and not api_key:
        logging.error("ETHERSCAN_API_KEY not set.")
        sys.exit(1)

    logging.info("Loading input CSV...")
    df = pd.read_csv(args.in_csv)
    for col in ("original_idx", "label", "contract_address"):
        if col not in df.columns:
            logging.error(f"Input CSV must contain column '{col}'")
            sys.exit(1)

    if args.limit is not None:
        df = df.head(args.limit).copy()

    base_dir = Path(args.out_dir)
    _ensure_dir(base_dir)

    out_rows = []
    total = len(df)
    logging.info(f"Total rows to process: {total}")

    iterator = df.itertuples(index=False)
    if _HAS_TQDM:
        iterator = tqdm(iterator, total=total, desc="Contracts", unit="addr")

    start_all = time.perf_counter()

    for idx, row in enumerate(iterator, start=1):
        orig_idx = int(getattr(row, "original_idx"))
        label = str(getattr(row, "label"))
        addr = str(getattr(row, "contract_address")).strip() if pd.notna(getattr(row, "contract_address")) else ""

        rec = {
            "original_idx": orig_idx,
            "label": label,
            "contract_address": addr,
            "etherscan_ok": False,
            "compiler_version": None,
            "n_files": 0,
            "compile_ok": False,
            "message": "",
        }

        if args.dry_run:
            out_rows.append(rec)
            continue

        if not addr or addr.lower() in ("nan", "none", "0x", "0x0"):
            rec["message"] = "Missing or invalid address"
            out_rows.append(rec)
            if args.fail_fast:
                logging.error(f"[{idx}/{total}] {addr} → {rec['message']}")
                break
            else:
                logging.warning(f"[{idx}/{total}] Skipping invalid address.")
                continue

        proj_dir = (base_dir / addr.lower())
        if args.skip_existing and proj_dir.exists():
            has_sol = any(proj_dir.rglob("*.sol"))
            if has_sol:
                rec["message"] = "Skipped existing project"
                out_rows.append(rec)
                logging.info(f"[{idx}/{total}] {addr} → skip (existing files)")
                if args.checkpoint_every and (idx % args.checkpoint_every == 0):
                    _checkpoint(out_rows, args.out_csv)
                continue

        try:
            t0 = time.perf_counter()
            time.sleep(args.rate_delay)
            logging.info(f"[{idx}/{total}] Fetching {addr} (chainid={args.chain_id}) ...")
            info = fetch_etherscan_sources(addr, api_key, args.timeout, args.chain_id)

            src_str = info.get("SourceCode", "") or ""
            compiler_version = _extract_semver(info.get("CompilerVersion", "") or "")
            contract_name = info.get("ContractName", "") or "Contract"
            opt_used = info.get("OptimizationUsed", "")
            runs = info.get("Runs", "")

            src_obj = _maybe_fix_wrapped_json(src_str)
            n_files, project_path = write_sources_to_disk(base_dir, addr, src_obj, None if src_obj else src_str, contract_name)

            rec["etherscan_ok"] = True
            rec["compiler_version"] = compiler_version or ""
            rec["n_files"] = n_files

            if n_files == 0:
                rec["compile_ok"] = False
                rec["message"] = "No files written (empty SourceCode or sanitized away)"
                logging.warning(f"[{idx}/{total}] {addr} → no files written; skipping compile")
                out_rows.append(rec)
                if args.checkpoint_every and (idx % args.checkpoint_every == 0):
                    _checkpoint(out_rows, args.out_csv)
                continue

            logging.info(f"[{idx}/{total}] {addr} → wrote {n_files} file(s) to {project_path}")

            ok, msg = try_compile(project_path, src_obj, compiler_version, opt_used, runs)
            rec["compile_ok"] = ok
            rec["message"] = msg

            dt = time.perf_counter() - t0
            logging.info(f"[{idx}/{total}] {addr} → compile_ok={ok} ({msg}) in {dt:.1f}s")

        except Exception as e:
            rec["message"] = f"Fetch/compile error: {e}"
            logging.exception(f"[{idx}/{total}] {addr} → ERROR")
            if args.fail_fast:
                out_rows.append(rec)
                _checkpoint(out_rows, args.out_csv)
                break

        out_rows.append(rec)
        if args.checkpoint_every and (idx % args.checkpoint_every == 0):
            _checkpoint(out_rows, args.out_csv)

    out_df = pd.DataFrame(out_rows).drop_duplicates(subset=["original_idx", "label"])
    out_df.to_csv(args.out_csv, index=False)
    elapsed = time.perf_counter() - start_all
    logging.info(f"[OK] Processed {len(out_df)} rows → {args.out_csv} in {elapsed:.1f}s")
    logging.info(f"Projects directory: {base_dir.resolve()}")

if __name__ == "__main__":
    main()
