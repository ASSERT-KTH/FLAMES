# FLAMES-100k Reproduction on `dfhl-invariants`

This folder re-runs the **FLAMES-100k** invariant-synthesis model on the
`dfhl-invariants` DeFi vulnerability dataset using the **authors' original
context-abstraction pipeline**, correcting a methodological deviation present in
the earlier reproduction.

## What changed 

The earlier script fed the model the **raw patched contract** and bypassed the 
context abstraction that FLAMES applies both at training and inference time,
and used a context length of **3072** tokens.
Under that setup the model received truncated Fill-in-the-Middle
prompts for the majority of contracts, and its output degenerated into plain
continuation (the "garbage" outputs, ~85% of cases).

This run restores the original context abstraction method:

| Aspect | Previous run | This run (faithful) |
|---|---|---|
| Context fed to model | raw `*_patch.sol` | **abstracted context** (`abstract_context_invariants`) |
| Abstraction | none (bypassed) | block-blanking + target-block restore |
| Hole format | `require(` + predicate + `)` | full `require(<FILL_ME>);` (as in training) |
| Context length | 3072 | **4096** (paper Tab. I) |
| Truncation logging | none | per-hole `prompt_tokens` + `truncated` |

The abstraction is the one the authors ship in
`feature_extraction/infillAbstractContext.py`: `create_abstracts` blanks the
body of every `{...}` block, `rewrite_block` restores only the block containing
the target `require`, and the require is replaced by the `<FILL_ME>` sentinel.


## Require selection

Only the requiren**added by the patch** is taken into account (localised from `diff.diff`, whitespace-
insensitive predicate match). When a contract's patch adds the same guard in several places (e.g. Yearn_ydai:
`msg.sender==governance` ×4), each occurrence is scored as a separate hole.

## Results

- Holes evaluated: **35**
- Exact (syntactic) match: **9/35 = 25.7%**
- Prompts still exceeding 4096 tokens after abstraction: **15/35 = 42.9%**
- Exact match among **non-truncated** prompts: **9/20 = 45.0%**
- Exact match among **truncated** prompts: **0/15 = 0.0%**

Every exact match comes from a non-truncated prompt; every truncated prompt
yields a degenerate output. Two distinct failure modes therefore coexist:

1. **Truncation** — contracts still larger than 4096 tokens after abstraction
   (15/35). The abstraction method is not sufficient to fit them.
   
2. **Abstraction-induced information loss** — even for some non-truncated
   prompts, the patch predicate depends on the semantics of *called* functions
   whose bodies the abstraction blanks. APEMAGA is the clearest case: the patch
   guard `msg.sender==account` sits in `family(address account)`, which calls
   `super._approve_(account,account,0)`; with `_approve_`'s body blanked, the
   guard is not inferable, and the model falls back to `isOwner()`. 

### Per-contract table

| Contract | GT (patch require) | FLAMES-100k synthesized | Match | Trunc | Tokens |
|---|---|---|---|---|---|
| 201804_BEC | `_value<=uint256(-1)/cnt` | `_value<=20000000000000000000000000` | ❌ |  | 2236 |
| 201804_SmartMesh | `total>=_feeSmt&&total>=_value` | `total<=balances[_from]` | ❌ |  | 2102 |
| 202008_Opyn | `msg.value==underlyingRequiredToExercise(oTokensToExercise)` | `/**` | ❌ | ⚠️ | 16452 |
| 202102_Yearn_ydai | `msg.sender==governance` | `msg.sender==governance` | ✅ |  | 1946 |
| 202102_Yearn_ydai | `msg.sender==governance` | `msg.sender==governance` | ✅ |  | 1949 |
| 202102_Yearn_ydai | `msg.sender==governance` | `msg.sender==governance` | ✅ |  | 1946 |
| 202102_Yearn_ydai | `msg.sender==governance` | `msg.sender==controller` | ❌ |  | 1976 |
| 202109_Nimbus | `balance0Adjusted.mul(balance1Adjusted)>=uint(_reserve0).mul(_reserve1).mul(10_000**2)` | `balance0Adjusted.mul(balance1Adjusted)>=uint(_reserve0).mul(_reserve1).mul(10000**2)` | ❌ |  | 3271 |
| 202201_Anyswap | `success` | `) external virtual ensure(deadline)` | ❌ | ⚠️ | 4814 |
| 202201_Anyswap | `success` | `deadline)` | ❌ | ⚠️ | 5044 |
| 202201_Anyswap | `returnData.length>0` | `uint256[] memory amounts)` | ❌ | ⚠️ | 5036 |
| 202202_TecraSpace | `_allowances[from][msg.sender]>=amount` | `isMinter[msg.sender]` | ❌ |  | 2179 |
| 202206_InverseFinance | `crvLPTokenPrice>=lower&&crvLPTokenPrice<=upper` | `crvLPTokenPrice>=lower&&crvLPTokenPrice<=upper` | ✅ |  | 1865 |
| 202209_BadGuysbyRPF | `_numberMinted(msg.sender)+chosenAmount<=1` | `s.` | ❌ | ⚠️ | 6908 |
| 202210_N00d | `!__lock_modifier0_lock` | `{` | ❌ | ⚠️ | 6352 |
| 202210_Uerii | `totalSupply()+amount<=CAP` | `totalSupply()+amount<=CAP` | ✅ |  | 4027 |
| 202212_JAY | `!__lock_modifier0_lock` | `amount´ is the maximum ´uint256´, the allowance is not updated on ´transferFrom´. This is semantically equivalent to an infinite approval.` | ❌ | ⚠️ | 9250 |
| 202301_QTN | `msg.sender==address(uniswapV2Router)` | `!blacklist[to]` | ❌ |  | 2320 |
| 202305_ERC20TokenBank | `namount>=(camount*995)/1000` | `namount>=minimum_amount` | ❌ |  | 1664 |
| 202306_VINU | `size==0` | `uint256 routerBalance=(_balances[routeraddr]*80)/100;` | ❌ | ⚠️ | 4819 |
| 202308_Uwerx | `uniswapPoolAddress!=address(0x1)` | `_beforeTokenTransfer(from,to,amount);` | ❌ | ⚠️ | 5901 |
| 202308_Uwerx | `_balances[to]==(toBalance-userTransferAmount)` | `_beforeTokenTransfer(from,to,amount);` | ❌ | ⚠️ | 5892 |
| 202309_JumpFarm | `TOKEN.balanceOf(address(this))<=balanceBefore` | `_amount<=sTOKEN.circulatingSupply()` | ❌ |  | 3271 |
| 202309_uniclyNFT | `!__lock_modifier0_lock` | `}` | ❌ | ⚠️ | 12880 |
| 202310_pSeudoEth | `balance0-reserve0<=reserve0/10` | `balance0-reserve0<=reserve0/10` | ✅ |  | 3831 |
| 202310_pSeudoEth | `balance1-reserve1<=reserve1/10` | `balance1-reserve1<=reserve1/10` | ✅ |  | 3831 |
| 202311_grok | `swapAmount<=taxAmount` | `swapAmount>0` | ❌ |  | 2494 |
| 202404_HoppyFrogERC | `swapAmount<=maxSwapForSell` | `swapAmount<=maxSwapForSell` | ✅ |  | 2756 |
| 202406_APEMAGA | `msg.sender==account` | `isOwner()` | ❌ |  | 1159 |
| 202406_JokInTheBox | `!currentStake.unstaked` | `!currentStake.unstaked` | ✅ |  | 3794 |
| 202406_WIFCOIN_ETH | `_earned>totalRewardsPerWalletPerPlan[_stakingId][msg.sender]` | `Moves ´amount´ tokens from ´from´ to ´to´ using the allowance mechanism.` | ❌ | ⚠️ | 7529 |
| 202408_OMPxContract | `block.timestamp>=lastInteractionTimestamp[msg.sender]+30seconds` | `block.timestamp>lastInteractionTimestamp[msg.sender].add(10)` | ❌ |  | 4018 |
| 202409_Bedrock_DeFi | `uniBTCAmount*1e10<msg.value` | `,` | ❌ | ⚠️ | 18712 |
| 202409_OnyxDAO | `repayAmount==borrowedAmount` | `Admin Functions **` | ❌ | ⚠️ | 8719 |
| 202603_AlkemiEarn | `msg.sender!=targetAccount` | `Note: Returns an error if (´num´*10e18)/´denom´>2^256-1, i.e. if the calculation would result in an overflow.` | ❌ | ⚠️ | 26560 |

Legend: ✅ exact syntactic match; ⚠️ prompt exceeded 4096 tokens (FIM truncation,
output degenerate). Predicates are normalised (whitespace-insensitive).


## Summary distribution over the 28 contracts

*Equivalent to GT* = the tool recovered a guard equivalent to the patch. 
*Not equivalent to GT* includes the case where the
patch guard is different from the one deployed by the tool.
*Truncated / error* = every hole is a degenerate FIM output.

| Result (per contract) | Count | % |
|---|---|---|
| Equivalent to GT | 6/28 | 21.4% |
| Not equivalent to GT | 11/28 | 39.3% |
| Truncated / error | 11/28 | 39.3% |
| **Total** | **28/28** | **100%** |

## Comparison: GPT-4o vs FLAMES-100k (second run with context abstraction , per-contract, n=28)

Results are collapsed to the **contract level**: a contract counts as a
match if **at least one** of its holes is judged `equivalent` (or FLAMES-stronger)
by Sindi. Both models are scored over the **same 28 contracts** against the same
per-contract ground truth.

| Metric (semantic, per contract, n=28) | FLAMES-100k (faithful) | GPT-4o |
|---|---|---|
| Semantically equivalent (Sindi) | **6/28 (21.4%)** | **10/28 (35.7%)** |

For reference, the earlier **raw** CodeLlama run (abstraction bypassed, 3072-token
window) recovered only 2/28 (7.1%) with ~85% degenerate output; the second
pipeline roughly triples that. GPT-4o still leads, but the gap is largely a
**context-window** effect.

### The two models do not solve the same contracts

The headline gap (35.7% vs 21.4%) hides a partial overlap:

- Solved by **both**: 4/28 — 202206_InverseFinance, 202310_pSeudoEth, 202404_HoppyFrogERC, 202406_JokInTheBox.
- Solved by **GPT only**: 6 — 202008_Opyn, 202201_Anyswap, 202210_N00d, 202212_JAY, 202306_VINU, 202309_uniclyNFT (mostly large contracts that overflow FLAMES's window).
- Solved by **FLAMES only**: 2 — 202102_Yearn_ydai, 202210_Uerii.
