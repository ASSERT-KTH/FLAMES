#!/usr/bin/env python3
"""
build_disl_subset.py

Given an input CSV with columns: original_idx, label
- Loads ASSERT-KTH/DISL (config='decomposed') from Hugging Face
- Selects rows by integer offset original_idx
- Joins back the 'contract_address' from DISL
- Writes a deduplicated CSV with columns: original_idx, label, contract_address

Usage:
  python build_disl_subset.py --in /path/to/disl-hardinv.csv --out disl_subset.csv

Notes:
- Requires `pip install datasets pandas`
- If DISL is gated, do `huggingface-cli login` first.
"""

import argparse
import sys
from typing import List, Tuple

import pandas as pd
from datasets import load_dataset


def load_pairs(csv_path: str) -> List[Tuple[int, str]]:
    df = pd.read_csv(csv_path)
    for col in ("original_idx", "label"):
        if col not in df.columns:
            raise ValueError(f"Input CSV must contain column '{col}'")
    # Keep only what we need; drop duplicates on the JOINT key
    df = df[["original_idx", "label"]].dropna().copy()
    df["original_idx"] = df["original_idx"].astype(int)
    pairs = list({(int(r.original_idx), str(r.label)) for r in df.itertuples()})
    return pairs


def main(args):
    in_csv = args.in_csv
    out_csv = args.out_csv

    # 1) Read pairs (original_idx, label)
    pairs = load_pairs(in_csv)
    idxs = sorted({p[0] for p in pairs})

    # 2) Load DISL decomposed split
    #    This will download/cache the Arrow dataset (random access supported)
    dec = load_dataset("ASSERT-KTH/DISL", "decomposed", split="train")

    # Basic sanity: confirm max index
    max_allowed = len(dec) - 1
    bad = [i for i in idxs if i < 0 or i > max_allowed]
    if bad:
        raise IndexError(
            f"Found {len(bad)} invalid original_idx values outside [0, {max_allowed}]. "
            f"Examples: {bad[:5]}"
        )

    # 3) Gather contract addresses by index
    rows = []
    for (orig_idx, lbl) in pairs:
        row = dec[int(orig_idx)]
        # Try known field names for the address
        contract_addr = (
            row.get("contract_address", None)
            or row.get("address", None)
            or row.get("contractAddress", None)
        )
        rows.append(
            {
                "original_idx": int(orig_idx),
                "label": str(lbl),
                "contract_address": contract_addr,
            }
        )

    # 4) Build output dataframe and save
    out_df = pd.DataFrame(rows)
    # Optional: warn about missing addresses
    missing = out_df["contract_address"].isna().sum()
    if missing:
        print(f"[WARN] {missing} rows have missing contract_address.", file=sys.stderr)

    # Deduplicate on the joint key (original_idx, label)
    out_df = out_df.drop_duplicates(subset=["original_idx", "label"]).reset_index(drop=True)
    out_df.to_csv(out_csv, index=False)
    print(f"[OK] Wrote {len(out_df)} rows → {out_csv}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--in", dest="in_csv", required=True, help="Input CSV with columns original_idx,label")
    parser.add_argument("--out", dest="out_csv", required=True, help="Output CSV to write")
    args = parser.parse_args()
    main(args)
