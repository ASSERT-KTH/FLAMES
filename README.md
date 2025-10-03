## FLAMES: Fine-tuning LLMs to Synthesize Security Invariants in Smart Contracts

FLAMES is a pipeline to synthesize Solidity invariants (require statements) that harden smart contracts without vulnerability labels. It comprises:
- Data curation (DISL dataset: deduplicated verified contracts)
- Supervised fine-tuning (FIM objective over real require predicates)
- Inference (pre-, post-, and sensitive-line placements)
- Evaluation: compilability (RQ1), semantic fidelity (RQ2), exploit prevention (RQ3)

Public artifacts:
- DISL dataset: https://huggingface.co/datasets/ASSERT-KTH/DISL
- FLAMES-100k weights: https://huggingface.co/ASSERT-KTH/FLAMES-100k-2406

## Repository layout

- analysis/
  - differencing-analysis/: RQ2 notebooks and figures (semantic comparison)
  - vulnerability-preventiveness-analysis/: RQ3 results processing/plots
- dataset/: scripts/notebooks for data prep; DISL references
- feature_extraction/: context abstraction utilities; Solidity parser
- invariant-checker/: Rust/Python helpers for parsing/testing
- raw-validation-results/
  - compilability-results/: RQ1 outputs
  - sb-heists/: RQ3 evaluation harness (Hardhat tests + notebooks)
- training/: SFT notebooks (data prep, tokenization, training, inference)

Generated artifacts (by notebooks/scripts):
- reports/aggregated/... (JSON/CSV with synthesized patches and validation)
- analysis/.../figures/*.pdf (paper figures)

## Reproduction checklist (TL;DR)

- Python: 3.10–3.11 (venv), Node.js + nvm installed
- Download DISL (or use provided HF handle) and set HF_TOKEN
- Run RQ1, RQ2 notebooks (compilability + semantic comparison)
- Run RQ3 validation against SB-Heists with Hardhat (choose Node/Hardhat path below)
- Regenerate plots under analysis/*

Details follow.

## Environment setup

### Python (recommended)

- macOS
- Python 3.10–3.11
- Jupyter, VS Code (optional), CUDA optional (training used 4×A100; inference/analysis CPU works)

Create a venv and install base deps:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip

# Project-specific deps (adjust as needed)
pip install -r dataset/requirements.txt
pip install -r feature_extraction/require-solidity-parser/requirements.txt

# Analysis tools used in notebooks
pip install jupyter tqdm pandas matplotlib numpy datasets python-dotenv
pip install sindi  # semantic comparator used in RQ2
```

Set your Hugging Face token (required to pull private/large datasets if applicable):
```bash
export HF_TOKEN=your_hf_token_here
```

### Node.js for Running RQ3 Harness (Using Hardhat)

You have two working paths; pick one and stick with it.

- Node 18 LTS via nvm
- Hardhat v2 installed locally in the SB-Heists evaluation folder

```bash
cd raw-validation-results/sb-heists/smartbugs-curated/0.4.x
# Ensure package.json does NOT contain "type": "module"
npm pkg delete type 2>/dev/null || true

# Pin Hardhat v2 locally
npm install --save-dev hardhat@^2

# Verify hardhat resolves to local v2
npx hardhat --version
```


## Data: DISL (deduplicated verified Solidity)

DISL is the largest deduplicated set of unique Solidity files.

- Public dataset: https://huggingface.co/datasets/ASSERT-KTH/DISL
- We provide decomposition and dedup logic; for replication, you can consume DISL directly.

Relevant assets:
- explore_data.ipynb (inspection)
- dataset/fiesta_to_json.py, remove_fiesta.py (legacy helpers)
- feature_extraction/ and invariant-checker/ (parsing/abstraction utilities)

## Fine-tuning (SFT) overview

We fine-tune CodeLlama2-7B with PEFT/QLoRA using a FIM objective:

- Input: abstracted contract context with require(<FILL_ME>)
- Label: the original predicate inside require(...)
- Context abstraction keeps state vars, target function body and callers/modifiers, function sigs

Reproducing training (reference):
- Tokenization.ipynb
- Training_streaming_noBatches.ipynb
- Inference.ipynb

Notes:
- Training used 4×A100 (80GB). For replication, use the released weights (FLAMES-100k).

## Inference: Synthesizing invariants

Primary helpers appear in notebooks; the key logic:
- Placeholders at chosen injection point:
  - pre (function entry), post (function exit), or target line (sensitive line)
- Generate a single-line predicate
- Reconstruct full contract by replacing the placeholder

See:
- raw-validation-results/sb-heists/inference-aggregated-script-new-deepseek-integration.ipynb (end-to-end synthesis/insertion harness; also demonstrates a drop-in generator adapter)
- feature_extraction/* (parser and abstraction)

## RQ1 — Compilability evaluation

Goal: Does injecting the synthesized require(...) keep the contract compilable?

How to run:
- Use your venv
- Open notebooks under raw-validation-results/compilability-results/ and/or the relevant sections in the DeepSeek/FLAMES inference notebook to generate and inject invariants into held-out contracts (DISL hard-invariant subset)
- Compile using original pragma settings (handled by the notebook/harness)

Outputs:
- CSV/JSON under reports/aggregated/ (compilation pass/fail)
- Aggregate plots generated under analysis/*


## RQ2 — Semantic fidelity vs. human-written invariants

Goal: Compare synthesized predicates to ground truth using Sindi.

How to run:
- comparison.ipynb (and companion notebooks)
- Ensure sindi is installed: pip install sindi
- Provide a 5k “hard invariant” set from DISL: [https://github.com/ASSERT-KTH/FLAMES/blob/master/Disl-hardinv/disl-hardinv.csv](https://github.com/ASSERT-KTH/FLAMES/blob/master/Disl-hardinv/disl-hardinv.csv) 
- The notebook computes:
  - Exact match
  - Semantically equivalent
  - Synth stronger / weaker
  - Inconclusive

Outputs:
- CSV: analysis/differencing-analysis/deepseek_comparison_results*.csv
- Figures: analysis/differencing-analysis/figures/*.pdf (e.g., predicate_comparison.pdf)

Expected trends (from paper):
- Exact matches increase with dataset size (e.g., ~1840/5000 for FLAMES-100k)
- Equivalences increase (e.g., ~386/5000)
- Stronger/weaker split increases vs. baseline

## RQ3 — Vulnerability prevention on SB-Heists

Goal: Do injected invariants prevent real exploits while preserving functionality?

Harness location:
- raw-validation-results/sb-heists/

Data layout:
- smartbugs-curated/0.4.x/ (contracts + tests)
- validation-script.ipynb (drives patching and execution)
- reports/aggregated/DeepSeek/ and reports/aggregated/ (JSON/CSV outputs)

Steps:
1) Prepare Node/Hardhat (see “Node.js for SB-Heists” above). For CJS path:
   - Use Node 18 and hardhat@^2 in 0.4.x
2) Open validation-script.ipynb
   - It loads “contracts_with_results” JSON (e.g., reports/aggregated/DeepSeek/contracts_PVP.json)
   - For each contract:
     - Creates variants (VL, pre, post, pre+post, PV, VP, PVP)
     - Runs functional tests and the exploit test via Hardhat
     - Logs pass/fail and saves patches/CSV
3) Check outputs:
   - CSV: reports/aggregated/validation_results_DeepSeek.csv (and *_fixed.csv)
   - Patches: reports/aggregated/DeepSeek/patches_DeepSeek/

Expected result (from paper):
- Best configuration prevents ~22/108 exploits while preserving tests
- Placement sensitivity: access control/reentrancy/arithmetic vary in response to pre/post

Notes:
- If Hardhat emits ESM errors, use the CJS path (Node 18 + hardhat@^2 + remove "type":"module")
- If you must stay on Node 22 + ESM, rename hardhat.config.js to hardhat.config.cjs or convert require() to import

## Figures and tables

Regenerate RQ2 figures:
- differencing-all-models.ipynb
- Produces predicate_comparison_with_deepseek.pdf and related plots under analysis/differencing-analysis/figures/

Regenerate RQ3 tables:
- analysis/vulnerability-preventiveness-analysis/*.ipynb
- Consumes reports/aggregated/*.csv produced by validation-script.ipynb

## Known pitfalls and troubleshooting

Hardhat ESM vs. CJS
- Symptom: “Hardhat only supports ESM projects” or “require is not defined in ES module scope”
- Fix (recommended): Node 18 + local hardhat@^2 + remove "type":"module" in the SB-Heists folder’s package.json

Trivial invariants
- Occasionally a model emits require(false)/require(true). The validation post-processing notebook (cleaning section) marks and adjusts these in the CSV.

GPU memory
- Training requires multiple GPUs (A100s). For replication, you can use released weights and run inference only.

HF downloads
- If huggingface dataset/models are large or private, set HF_TOKEN and optionally a cache_dir.

## Citation

If you use this code, datasets, or figures, please cite the paper:
```bibtex
to be published... 
```
