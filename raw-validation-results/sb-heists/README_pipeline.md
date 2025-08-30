# FLAMES Smart Contract Validation

This repository implements a pipeline to:
1. **Analyze** Solidity contracts with annotated vulnerabilities.  
2. **Generate candidate patches** using a fine-tuned LLaMA model with **PEFT (LoRA)**.  
3. **Apply and evaluate** different patching strategies (`VL`, `pre`, `post`, `PVP`, etc.).  
4. **Produce aggregated reports** in JSON, CSV, and TXT formats.  

---

## 📂 Pipeline

### 1. Patch Generation
- Load the vulnerable contracts dataset (`smartbugs-curated`).
- Remove markers `// <yes> <report>`.
- Create **prompts** with placeholders `require(<FILL_ME>);`.
- Use FLAMES models + CodeLlama.  
- Generate JSON outputs:
  - `contract_no_comment.json` → clean contracts.
  - `contract_VL.json` → patch applied at the vulnerable line.
  - `contract_PV.json` → patch applied at pre + VL.
  - `contracts_PVP.json` → patch applied at pre + VL + post (for isolated is the same, but called _post.json)

### 2. Patch Validation
- Load contracts and generated JSONs.
- Apply patching strategies:
  - `VL`, `pre`, `post`, `pre_post`, `pre_VL`, `VL_post`, `pre_VL_post`.
- Validate using **`validation_library`** (execution and verification).
- Generate reports:
  - CSV with results (`validation_results_20K.csv`).
  - Cleaned version (`validation_results_20K_fixed.csv`).
  - Isolated patches in `patches_CL/`.

---

## 📑 Dependencies
- [transformers](https://huggingface.co/docs/transformers/index)  
- [peft](https://huggingface.co/docs/peft/index)  
- [torch](https://pytorch.org/)  
- [bitsandbytes](https://github.com/TimDettmers/bitsandbytes)  
- [tqdm](https://tqdm.github.io/)  
- [python-dotenv](https://github.com/theskumar/python-dotenv)  

---

## 📊 Output

### JSON

#### `contract_no_comment.json`
Contracts without vulnerability markers:
```json
[
  ["ContractA.sol", "pragma solidity ^0.4.24;\ncontract A {...}", [45]],
  ["ContractB.sol", "pragma solidity ^0.4.24;\ncontract B {...}", [30]]
]
```

#### `contract_VL.json`
Patch applied only to the vulnerable line:
```json
{
  "ContractA.sol": [
    [
      "pragma solidity ^0.4.24;\ncontract A {...}",
      {
        "VL": [45, "require(amount > 0);"],
        "pre": [12, ""],
        "post": [60, ""]
      }
    ]
  ]
}
```

#### `contracts_PVP.json`
Patch applied to pre + vulnerable + post:
```json
{
  "ContractB.sol": [
    [
      "pragma solidity ^0.4.24;\ncontract B {...}",
      {
        "VL": [30, "require(balance >= amount);"],
        "pre": [20, "require(msg.sender != address(0));"],
        "post": [55, "require(state == ACTIVE);"]
      }
    ]
  ]
}
```

---

### CSV

#### `validation_results_20K_fixed.csv`
Patches with `require(false);` or empty strings are considered **invalid** and marked `False` in the fixed CSV.
Cleaned version (`require(false);` patches marked as `False`):
```csv
Solidity_file_name,vulnerability_type,vulnerable_line_number,vulnerability_function_entry_line,vulnerability_function_end_line,VL,pre_post,pre,post,pre_VL_post,pre_VL,VL_post
ContractA.sol,reentrancy,45,12,60,{'Sanity_Test_Success': True, 'Exploit_Covered': True},{'Sanity_Test_Success': True, 'Exploit_Covered': False},{'Sanity_Test_Success': True, 'Exploit_Covered': True},{'Sanity_Test_Success': True, 'Exploit_Covered': False},{'Sanity_Test_Success': False, 'Exploit_Covered': False},{'Sanity_Test_Success': True, 'Exploit_Covered': True},{'Sanity_Test_Success': False, 'Exploit_Covered': False}
```

---

### TXT

#### `contract_no_comment.txt`
List of contracts without vulnerability annotations:
```
ContractA.sol
ContractB.sol
ContractC.sol
```

---

## 📋 Output Summary

| File | Format | Content |
|------|---------|-----------|
| `contract_no_comment.json` | JSON | Contracts without `// <yes> <report>` markers |
| `contract_VL.json` | JSON | Contracts patched only at the vulnerable line |
| `contract_PV.json` | JSON | Contracts patched at pre + VL |
| `contracts_PVP.json` | JSON | Contracts patched at pre + VL + post |
| `validation_results_20K.csv` | CSV | Raw patching strategy results |
| `validation_results_20K_fixed.csv` | CSV | Cleaned results excluding false positives (`require(false)`) |
| `contract_no_comment.txt` | TXT | List of contracts without annotations |
| `patches_CL/` | Solidity files | Saved patches, separated by strategy (`VL`, `pre`, `post`, etc.) |


