#!/usr/bin/env python3
import argparse, logging, sys, json, re, time
from pathlib import Path
from typing import Optional, List, Tuple

import pandas as pd

from solcx import (
    install_solc, set_solc_version, compile_standard, compile_source,
    get_installed_solc_versions, get_installable_solc_versions
)
from solcx.exceptions import SolcError

try:
    from tqdm import tqdm
    _HAS_TQDM = True
except ImportError:
    _HAS_TQDM = False

SEMVER_RE = re.compile(r"""(\d+\.\d+\.\d+)""" )
PRAGMA_RE = re.compile(r"""pragma\s+solidity\s+([^;]+);""", re.IGNORECASE)

def setup_logging(level: str):
    lvl = getattr(logging, level.upper(), logging.INFO)
    logging.basicConfig(level=lvl, format="%(levelname)s %(message)s")

def list_sol_files(project_dir: Path) -> list[Path]:
    return [p for p in project_dir.rglob("*.sol") if p.is_file() and p.stat().st_size > 0]

def read_pragmas(project_dir: Path) -> list[str]:
    pragmas = []
    for fp in project_dir.rglob("*.sol"):
        try:
            txt = fp.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        pragmas += [m.group(1).strip() for m in PRAGMA_RE.finditer(txt)]
    return pragmas

def choose_version_from_pragmas(pragmas: list[str]) -> Optional[str]:
    # 1) exact semver anywhere wins
    exacts = []
    for p in pragmas:
        for m in SEMVER_RE.finditer(p):
            exacts.append(m.group(1))
    if exacts:
        def tv(v): x,y,z = v.split("."); return (int(x), int(y), int(z))
        return max(exacts, key=tv)

    # 2) infer major.minor from a range/caret/tilde and pick highest installable patch
    mm = None
    for p in pragmas:
        m = re.search(r"(\d+)\.(\d+)\.", p)
        if m:
            mm = (int(m.group(1)), int(m.group(2)))
            break
    if not mm:
        return None

    maj, min_ = mm
    try:
        avail = [str(v) for v in get_installable_solc_versions()]
    except Exception:
        avail = []
    candidates = []
    for v in avail:
        m = SEMVER_RE.fullmatch(v)
        if not m: 
            continue
        X, Y, Z = map(int, v.split("."))
        if X == maj and Y == min_:
            candidates.append((X, Y, Z, v))
    if candidates:
        candidates.sort()
        return candidates[-1][3]
    return f"{maj}.{min_}.20"  # best-effort fallback

def load_meta_version(project_dir: Path) -> Optional[str]:
    meta = project_dir / "etherscan_meta.json"
    if not meta.exists():
        return None
    try:
        info = json.loads(meta.read_text())
    except Exception:
        return None
    comp_raw = ((info.get("etherscan") or {}).get("CompilerVersion") or "").strip()
    m = SEMVER_RE.search(comp_raw)
    return m.group(1) if m else None

def find_standard_json(project_dir: Path) -> Optional[Path]:
    p = project_dir / "standard_input.json"
    return p if p.exists() else None

def ensure_compiler(version: str) -> Tuple[bool, str]:
    installed = [str(v) for v in get_installed_solc_versions()]
    if version not in installed:
        try:
            install_solc(version)
        except Exception as e:
            return False, f"Failed to install solc {version}: {e}"
    try:
        set_solc_version(version)
    except Exception as e:
        return False, f"Failed to set solc {version}: {e}"
    return True, "OK"

def compile_project(project_dir: Path, semver: str, log_lines: list[str]) -> Tuple[bool,str,bool,int]:
    """
    Returns: (ok, message, used_std_json, num_sol_files)
    """
    sols = list_sol_files(project_dir)
    std = find_standard_json(project_dir)
    used_std = bool(std)
    nsol = len(sols)

    log_lines.append(f"Detected standard_input.json: {used_std}")
    log_lines.append(f"Detected .sol files: {nsol}")
    if not used_std and nsol == 0:
        return False, "No non-empty Solidity sources found", used_std, nsol

    ok, msg = ensure_compiler(semver)
    log_lines.append(f"ensure_compiler({semver}) → {ok}, {msg}")
    if not ok:
        return False, msg, used_std, nsol

    try:
        if used_std:
            data = json.loads(std.read_text())
            if "language" not in data: data["language"] = "Solidity"
            if "settings" not in data: data["settings"] = {}
            if "optimizer" not in data["settings"]:
                data["settings"]["optimizer"] = {"enabled": False, "runs": 200}
            _ = compile_standard(data)
        else:
            _ = compile_source(sols[0].read_text())
        return True, "Compiled OK (offline)", used_std, nsol
    except SolcError as e:
        detail = f"SolcError: {e}\nstdout:\n{getattr(e, 'stdout_data', '')}\nstderr:\n{getattr(e, 'stderr_data', '')}"
        return False, detail, used_std, nsol
    except Exception as e:
        return False, f"Compilation error: {e}", used_std, nsol

def main():
    ap = argparse.ArgumentParser(description="Offline recompile failed contracts with per-address logs (no API calls)." )
    ap.add_argument("--in", dest="in_csv", required=True, help="failed_compilations.csv")
    ap.add_argument("--projects-dir", default="./contracts", help="Folder with <address>/ subdirs")
    ap.add_argument("--logs-dir", default="./failed_logs", help="Where to write per-address logs")
    ap.add_argument("--out", dest="out_csv", default="failed_logs.csv", help="Consolidated results CSV")
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--log-level", default="INFO", choices=["DEBUG","INFO","WARNING","ERROR"])
    args = ap.parse_args()

    setup_logging(args.log_level)

    df = pd.read_csv(args.in_csv)
    needed = {"original_idx","label","contract_address"}
    if not needed.issubset(df.columns):
        logging.error(f"Input CSV must have columns: {needed}")
        sys.exit(1)

    has_comp = "compiler_version" in df.columns

    if args.limit is not None:
        df = df.head(args.limit).copy()

    root = Path(args.projects_dir)
    logs_root = Path(args.logs_dir)
    logs_root.mkdir(parents=True, exist_ok=True)

    results = []
    iterator = df.itertuples(index=False)
    if _HAS_TQDM:
        iterator = tqdm(iterator, total=len(df), desc="Recompile (offline, verbose)", unit="addr")

    for row in iterator:
        orig_idx = int(getattr(row, "original_idx"))
        label = str(getattr(row, "label"))
        addr = str(getattr(row, "contract_address")).strip().lower()
        proj = root / addr

        log_lines: list[str] = []
        log_lines.append(f"original_idx={orig_idx}")
        log_lines.append(f"label={label}")
        log_lines.append(f"address={addr}")
        log_lines.append(f"project_dir={proj}")

        rec = {
            "original_idx": orig_idx,
            "label": label,
            "contract_address": addr,
            "compiler_version_used": "",
            "std_json_used": False,
            "num_sol_files": 0,
            "compile_ok_offline": False,
            "message_offline_first": "",
            "elapsed_s": 0.0,
        }

        if not proj.exists():
            msg = "Project folder missing"
            rec["message_offline_first"] = msg
            log_lines.append(msg)
            (logs_root / f"{addr}.log").write_text("\n".join(log_lines))
            results.append(rec)
            continue

        semver = None
        if has_comp:
            try:
                v = str(getattr(row, "compiler_version")).strip()
                if v and SEMVER_RE.fullmatch(v):
                    semver = v
                    log_lines.append(f"compiler_version from CSV: {semver}")
            except Exception:
                pass
        if semver is None:
            mv = load_meta_version(proj)
            if mv:
                semver = mv
                log_lines.append(f"compiler_version from etherscan_meta.json: {semver}")
        if semver is None:
            pragmas = read_pragmas(proj)
            semver = choose_version_from_pragmas(pragmas)
            log_lines.append(f"compiler_version from pragma heuristic: {semver} (pragmas: {len(pragmas)})")

        rec["compiler_version_used"] = semver or ""

        t0 = time.perf_counter()
        ok, msg, used_std, nsol = compile_project(proj, semver or "", log_lines)
        rec["compile_ok_offline"] = ok
        rec["std_json_used"] = bool(used_std)
        rec["num_sol_files"] = int(nsol)
        rec["message_offline_first"] = (msg.splitlines()[0] if isinstance(msg, str) and len(msg) else "")
        rec["elapsed_s"] = round(time.perf_counter() - t0, 2)

        log_lines.append(f"RESULT compile_ok={ok}")
        log_lines.append("MESSAGE BEGIN")
        log_lines.append(str(msg))
        log_lines.append("MESSAGE END")

        (logs_root / f"{addr}.log").write_text("\n".join(log_lines))

        results.append(rec)

    out = pd.DataFrame(results)
    out.to_csv(args.out_csv, index=False)
    logging.info(f"[OK] Wrote {len(out)} rows → {args.out_csv}")
    logging.info(f"Per-address logs are in: {logs_root.resolve()}")

if __name__ == "__main__":
    main()
