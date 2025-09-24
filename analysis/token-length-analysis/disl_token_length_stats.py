#!/usr/bin/env python3
"""
DISL Token Length Stats — full-dataset capable, HF token-ready, with persistent per-row outputs.

What’s new:
- Stores per-row token length with a stable key (sha256 of source_code) so you can reuse the results later.
- Writes to Parquet by default (compact & fast); falls back to JSONL if pyarrow is unavailable.
- Lets you include selected metadata columns from the dataset for later joins/analysis.
- Still writes the compact uint32 binary too (for quick percentiles/plots).

Typical full pass on the deduplicated split (use whatever config is the dedup set in your release; often "decomposed"):
python disl_token_length_stats.py \
  --configs decomposed \
  --tokenizer codellama/CodeLlama-7b-hf \
  --hf-token $HUGGING_FACE_HUB_TOKEN \
  --full-pass \
  --batch-size 128 \
  --plot \
  --persist \
  --persist-fields file_path contract_address compiler_version

Output files in ./disl_token_stats:
  - lengths_<config>.bin            (uint32; tiny; good for quick stats)
  - lengths_<config>.parquet/jsonl  (sha256 key + tokens + optional metadata)
  - stats_<config>.json             (summary stats)
  - survivorship_<config>.png       (plot, if --plot)
"""
import argparse
import json
import os
import random
import struct
import hashlib
from typing import Iterable, List, Tuple, Dict, Optional

import numpy as np
from datasets import load_dataset
from tqdm import tqdm

try:
    from transformers import AutoTokenizer
except Exception as e:
    raise SystemExit("Please install transformers: pip install transformers\n" + str(e))

# Optional parquet
HAVE_PARQUET = False
try:
    import pyarrow as pa
    import pyarrow.parquet as pq
    HAVE_PARQUET = True
except Exception:
    HAVE_PARQUET = False

# Optional plotting
try:
    import matplotlib.pyplot as plt
    HAVE_PLT = True
except Exception:
    HAVE_PLT = False


DATASET_NAME = "ASSERT-KTH/DISL"
SOURCE_COL = "source_code"


def apply_hf_token(token: Optional[str]) -> None:
    if not token:
        return
    os.environ["HUGGING_FACE_HUB_TOKEN"] = token
    os.environ["HF_TOKEN"] = token


def reservoir_sample(iterable: Iterable[dict], k: int, seed: int) -> List[dict]:
    rng = random.Random(seed)
    sample: List[dict] = []
    for i, item in enumerate(iterable):
        if i < k:
            sample.append(item)
        else:
            j = rng.randint(0, i)
            if j < k:
                sample[j] = item
    return sample


def sha256_text(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8", "ignore")).hexdigest()


def tokenize_lengths(texts: List[str], tokenizer, batch_size: int = 64) -> List[int]:
    lengths: List[int] = []
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]
        enc = tokenizer(
            batch,
            add_special_tokens=False,
            return_attention_mask=False,
            return_token_type_ids=False,
            truncation=False,
        )
        lengths.extend([len(x) for x in enc["input_ids"]])
    return lengths


def survivorship_xy(lengths_arr: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    arr = np.sort(lengths_arr.astype(np.int64))
    n = arr.size
    if n == 0:
        return arr, np.array([])
    y = 1.0 - (np.arange(1, n+1) / n)
    return arr, y


def plot_survivorship_from_array(lengths_arr: np.ndarray, label: str, thresholds: List[int], out_path: str):
    if not HAVE_PLT:
        print("[WARN] matplotlib not available; skipping plot.")
        return
    xs, ys = survivorship_xy(lengths_arr)
    import matplotlib.pyplot as plt
    plt.figure(figsize=(8, 5))
    if xs.size > 0:
        plt.plot(xs, ys, label=label)
        for t in thresholds:
            plt.axvline(x=t, linestyle="--", label=f"x={t}")
        plt.xscale("log")
    plt.xlabel("Tokenized length (log scale)")
    plt.ylabel("Survivorship (1 - CDF)")
    plt.title(f"Context length survivorship: {label}")
    # Dedup legend labels
    handles, labels = plt.gca().get_legend_handles_labels()
    seen = set(); new_h = []; new_l = []
    for h,l in zip(handles, labels):
        if l not in seen:
            new_h.append(h); new_l.append(l); seen.add(l)
    plt.legend(new_h, new_l, loc="best")
    plt.grid(True)
    plt.savefig(out_path, dpi=180, bbox_inches="tight")
    plt.close()
    print(f"[plot] Saved {out_path}")


def load_tokenizer(model_id: str, token: Optional[str]):
    try:
        return AutoTokenizer.from_pretrained(model_id, use_fast=True, token=token)
    except TypeError:
        return AutoTokenizer.from_pretrained(model_id, use_fast=True, use_auth_token=token)


class ParquetRowWriter:
    """Append rows to a parquet file in batches using PyArrow. Fallback to JSONL if pyarrow missing."""
    def __init__(self, path: str, fields: List[str], batch_size: int = 5000, use_parquet: bool = True):
        self.path = path
        self.fields = fields
        self.batch_size = batch_size
        self.rows: List[Dict] = []
        self.use_parquet = use_parquet and HAVE_PARQUET
        self.writer = None  # type: ignore

        if self.use_parquet:
            # Defer schema until first write (so we can infer dtypes)
            pass
        else:
            # JSONL fallback: truncate existing file
            open(self.path, "w").close()

    def append(self, row: Dict):
        self.rows.append(row)
        if len(self.rows) >= self.batch_size:
            self.flush()

    def flush(self):
        if not self.rows:
            return
        if self.use_parquet:
            table = pa.Table.from_pylist(self.rows)
            if self.writer is None:
                self.writer = pq.ParquetWriter(self.path, table.schema, compression="zstd")
            self.writer.write_table(table)
        else:
            # JSONL fallback
            with open(self.path, "a", encoding="utf-8") as f:
                for r in self.rows:
                    f.write(json.dumps(r, ensure_ascii=False) + "\n")
        self.rows = []

    def close(self):
        self.flush()
        if self.writer is not None:
            self.writer.close()


def main():
    ap = argparse.ArgumentParser(description="DISL token length stats with persistent per-row outputs.")
    ap.add_argument("--dataset-name", default=DATASET_NAME)
    ap.add_argument("--configs", nargs="+", default=["decomposed"], help="Configs: raw, decomposed")
    ap.add_argument("--split", default="train")
    ap.add_argument("--tokenizer", default="codellama/CodeLlama-7b-hf", help="HF tokenizer id")
    ap.add_argument("--hf-token", default=None, help="HF API token (or set HUGGING_FACE_HUB_TOKEN/HF_TOKEN).")
    ap.add_argument("--thresholds", type=int, nargs="*", default=[2048, 4096, 8192, 16384])
    ap.add_argument("--output-dir", default="disl_token_stats")

    # Persistence
    ap.add_argument("--persist", action="store_true", help="Persist per-row token length to parquet/jsonl with sha256 key")
    ap.add_argument("--persist-format", choices=["parquet", "jsonl"], default="parquet",
                    help="File format for per-row outputs (default: parquet; falls back to jsonl if pyarrow missing)")
    ap.add_argument("--persist-fields", nargs="*", default=["file_path", "contract_address", "compiler_version"],
                    help="Additional dataset fields to include if present")

    # Sampling mode (quick)
    ap.add_argument("--sample-size", type=int, default=100000)
    ap.add_argument("--streaming", action="store_true")
    ap.add_argument("--seed", type=int, default=1337)

    # Full pass mode (entire split)
    ap.add_argument("--full-pass", action="store_true")
    ap.add_argument("--batch-size", type=int, default=128)
    ap.add_argument("--save-csv", action="store_true")
    ap.add_argument("--plot", action="store_true")

    args = ap.parse_args()

    token = args.hf_token or os.environ.get("HUGGING_FACE_HUB_TOKEN") or os.environ.get("HF_TOKEN")
    apply_hf_token(token)

    os.makedirs(args.output_dir, exist_ok=True)

    print(f"[info] Loading tokenizer: {args.tokenizer}")
    tokenizer = load_tokenizer(args.tokenizer, token=token)

    for cfg in args.configs:
        print(f"\n=== Config: {cfg} ===")
        if args.full_pass:
            print(f"[info] Full pass over {args.dataset_name}:{cfg}/{args.split} (streaming).")
            ds = load_dataset(args.dataset_name, cfg, split=args.split, streaming=True)
            lengths_bin = os.path.join(args.output_dir, f"lengths_{cfg}.bin")
            if os.path.exists(lengths_bin):
                os.remove(lengths_bin)

            # Prepare per-row writer
            perrow_path = os.path.join(
                args.output_dir,
                f"lengths_{cfg}.{'parquet' if (args.persist_format=='parquet' and HAVE_PARQUET) else 'jsonl'}"
            )
            perrow_writer = None
            if args.persist:
                use_parquet = (args.persist_format == "parquet") and HAVE_PARQUET
                perrow_writer = ParquetRowWriter(perrow_path, fields=["sha256", "tokens"] + args.persist_fields,
                                                 batch_size=5000, use_parquet=use_parquet)
                if not HAVE_PARQUET and args.persist_format == "parquet":
                    print("[warn] pyarrow not available; falling back to JSONL.")

            buf_examples: List[dict] = []
            written = 0

            with open(lengths_bin, "ab") as fbin:
                pbar = tqdm(ds, desc="Full pass (streaming)")
                for ex in pbar:
                    sc = ex.get(SOURCE_COL)
                    if not sc:
                        continue
                    buf_examples.append(ex)
                    if len(buf_examples) >= args.batch_size:
                        texts = [e[SOURCE_COL] for e in buf_examples]
                        lens = tokenize_lengths(texts, tokenizer, batch_size=args.batch_size)

                        # write compact binary + (optional) per-row parquet/jsonl
                        for e, L in zip(buf_examples, lens):
                            fbin.write(struct.pack("<I", int(L)))
                            written += 1
                            if perrow_writer is not None:
                                row = {"sha256": sha256_text(e[SOURCE_COL]), "tokens": int(L)}
                                # include requested metadata if present
                                for fld in args.persist_fields:
                                    if fld in e and e[fld] is not None:
                                        row[fld] = e[fld]
                                perrow_writer.append(row)

                        buf_examples.clear()
                        if written % (args.batch_size * 10) == 0:
                            pbar.set_postfix_str(f"written={written}")

                if buf_examples:
                    texts = [e[SOURCE_COL] for e in buf_examples]
                    lens = tokenize_lengths(texts, tokenizer, batch_size=args.batch_size)
                    for e, L in zip(buf_examples, lens):
                        fbin.write(struct.pack("<I", int(L)))
                        written += 1
                        if perrow_writer is not None:
                            row = {"sha256": sha256_text(e[SOURCE_COL]), "tokens": int(L)}
                            for fld in args.persist_fields:
                                if fld in e and e[fld] is not None:
                                    row[fld] = e[fld]
                            perrow_writer.append(row)
                    buf_examples.clear()

            if perrow_writer is not None:
                perrow_writer.close()

            print(f"[info] Wrote {written} lengths to {lengths_bin}")
            # Load for stats/plot
            mm = np.memmap(lengths_bin, dtype=np.uint32, mode="r")
            arr = np.array(mm, dtype=np.int64)

            stats = {
                "count": int(arr.size) if arr.size else 0,
                "min": int(arr.min()) if arr.size else None,
                "max": int(arr.max()) if arr.size else None,
                "mean": float(arr.mean()) if arr.size else None,
                "std": float(arr.std(ddof=0)) if arr.size else None,
                "p50": int(np.percentile(arr, 50)) if arr.size else None,
                "p90": int(np.percentile(arr, 90)) if arr.size else None,
                "p95": int(np.percentile(arr, 95)) if arr.size else None,
                "p99": int(np.percentile(arr, 99)) if arr.size else None,
                "p99_9": int(np.percentile(arr, 99.9)) if arr.size else None,
                "above_thresholds": {str(t): float((arr > t).mean()) if arr.size else None for t in args.thresholds},
            }

            out_json = os.path.join(args.output_dir, f"stats_{cfg}.json")
            with open(out_json, "w", encoding="utf-8") as f:
                json.dump(stats, f, indent=2)
            print(f"[write] {out_json}")

            if args.save_csv:
                out_csv = os.path.join(args.output_dir, f"lengths_{cfg}.csv")
                with open(out_csv, "w", encoding="utf-8") as f:
                    f.write("idx,tokens\n")
                    for i, L in enumerate(arr.tolist()):
                        f.write(f"{i},{int(L)}\n")
                print(f"[write] {out_csv}")

            if args.plot:
                out_png = os.path.join(args.output_dir, f"survivorship_{cfg}.png")
                plot_survivorship_from_array(arr, label=cfg, thresholds=args.thresholds, out_path=out_png)

            print("\n=== Summary ===")
            print(f"[{cfg}] n={stats['count']} min={stats['min']} p50={stats['p50']} p90={stats['p90']} "
                  f"p95={stats['p95']} p99={stats['p99']} p99.9={stats['p99_9']} max={stats['max']}")
            for t, frac in stats["above_thresholds"].items():
                print(f"  > {t} tokens: {frac*100:.1f}%" if frac is not None else f"  > {t} tokens: NA")

        else:
            # SAMPLE MODE (kept for quick comparisons)
            print(f"[info] Sample mode on {args.dataset_name}:{cfg}/{args.split}; streaming={args.streaming}")
            ds = load_dataset(args.dataset_name, cfg, split=args.split, streaming=args.streaming)

            if args.streaming:
                sampled_rows = reservoir_sample(ds, k=args.sample_size, seed=args.seed)
            else:
                ds = ds.shuffle(seed=args.seed)
                if args.sample_size > 0:
                    ds = ds.select(range(min(args.sample_size, len(ds))))
                sampled_rows = list(ds)

            texts: List[str] = []
            missing = 0
            for ex in sampled_rows:
                sc = ex.get(SOURCE_COL)
                if sc is None:
                    missing += 1
                    continue
                texts.append(sc)
            if missing:
                print(f"[warn] Missing {missing} examples without '{SOURCE_COL}'")

            lengths = tokenize_lengths(texts, tokenizer=tokenizer, batch_size=args.batch_size)
            arr = np.array(lengths, dtype=np.int64)

            # Optional per-row persistence in sample mode
            if args.persist:
                use_parquet = (args.persist_format == "parquet") and HAVE_PARQUET
                perrow_path = os.path.join(
                    args.output_dir,
                    f"lengths_{cfg}.{'parquet' if use_parquet else 'jsonl'}"
                )
                writer = ParquetRowWriter(perrow_path, fields=["sha256", "tokens"] + args.persist_fields,
                                          batch_size=5000, use_parquet=use_parquet)
                for ex, L in zip(sampled_rows, lengths):
                    row = {"sha256": sha256_text(ex[SOURCE_COL]), "tokens": int(L)}
                    for fld in args.persist_fields:
                        if fld in ex and ex[fld] is not None:
                            row[fld] = ex[fld]
                    writer.append(row)
                writer.close()

            # Save CSV of sampled lengths
            out_csv = os.path.join(args.output_dir, f"lengths_{cfg}.csv")
            with open(out_csv, "w", encoding="utf-8") as f:
                f.write("idx,tokens\n")
                for i, L in enumerate(lengths):
                    f.write(f"{i},{int(L)}\n")
            print(f"[write] {out_csv}")

            stats = {
                "count": int(arr.size),
                "min": int(arr.min()) if arr.size else None,
                "max": int(arr.max()) if arr.size else None,
                "mean": float(arr.mean()) if arr.size else None,
                "std": float(arr.std(ddof=0)) if arr.size else None,
                "p50": int(np.percentile(arr, 50)) if arr.size else None,
                "p90": int(np.percentile(arr, 90)) if arr.size else None,
                "p95": int(np.percentile(arr, 95)) if arr.size else None,
                "p99": int(np.percentile(arr, 99)) if arr.size else None,
                "p99_9": int(np.percentile(arr, 99.9)) if arr.size else None,
                "above_thresholds": {str(t): float((arr > t).mean()) if arr.size else None for t in args.thresholds},
            }
            out_json = os.path.join(args.output_dir, f"stats_{cfg}.json")
            with open(out_json, "w", encoding="utf-8") as f:
                json.dump(stats, f, indent=2)
            print(f"[write] {out_json}")

            if args.plot:
                out_png = os.path.join(args.output_dir, f"survivorship_{cfg}.png")
                plot_survivorship_from_array(arr, label=cfg, thresholds=args.thresholds, out_path=out_png)

            print("\n=== Summary ===")
            print(f"[{cfg}] n={stats['count']} min={stats['min']} p50={stats['p50']} p90={stats['p90']} "
                  f"p95={stats['p95']} p99={stats['p99']} p99.9={stats['p99_9']} max={stats['max']}")
            for t, frac in stats["above_thresholds"].items():
                print(f"  > {t} tokens: {frac*100:.1f}%" if frac is not None else f"  > {t} tokens: NA")


if __name__ == "__main__":
    main()