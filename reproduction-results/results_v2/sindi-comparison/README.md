# Sindi Scoring 

This folder applies **Sindi** semantic comparison to the synthesized invariants
of the FLAMES-100k run with context abstraction. For every hole the
synthesized predicate is compared against the patch ground-truth predicate using Sindi.

## Method

- Engine: `sindi.comparator.Comparator().compare(first, second)`.
- Convention: `first` = FLAMES synthesized predicate, `second` = ground truth.
  Hence *"The second predicate is stronger."* means the patch guard is stronger
  than what the tool produced (i.e. **not** recovered).
- FLAMES emits plain Solidity, so the only rewrites applied
  before Sindi are: strip the `require(<pred>, "msg")` error message, drop digit
  separators (`10_000`→`10000`), and rewrite the power operator `**`→`^` which
  Sindi's tokenizer does not accept. These are purely syntactic.

## Truncated outputs are not comparable

FLAMES produces degenerate output whenever the FIM prompt exceeds 4096 tokens. 
Those outputs (`{`, `,`, `) external ...`) are not
valid predicates in any syntax, so Sindi raises a tokenizer `ValueError`. They
are recorded verbatim (e.g. `ValueError: Unexpected token COMMA`) and grouped as
**error**.

## Results

- Holes: **35** (truncated 15, non-truncated 20)
- Syntactic exact: **9/35 = 25.7%**
- Semantic (equivalent or FLAMES-stronger): **9/35 = 25.7%**
- On non-truncated holes only: syntactic 9/20 (45.0%),
  semantic 9/20 (45.0%)

Sindi verdict distribution: {'none': 11, 'error': 14, 'exact_or_equiv': 9, 'gt_stronger': 1}

### Per-hole table

| Contract | GT (patch require) | FLAMES synthesized | Sindi verdict (raw) | Trunc |
|---|---|---|---|---|
| 201804_BEC | `_value<=uint256(-1)/cnt` | `_value<=20000000000000000000000000` | The predicates are not equivalent and neither is stronger. |  |
| 201804_SmartMesh | `total>=_feeSmt&&total>=_value` | `total<=balances[_from]` | The predicates are not equivalent and neither is stronger. |  |
| 202008_Opyn | `msg.value==underlyingRequiredToExercise(oTokensToExercise)` | `/**` | ValueError: Unexpected token DIVIDE at position 0 | ⚠️ |
| 202102_Yearn_ydai | `msg.sender==governance` | `msg.sender==governance` | The predicates are equivalent. |  |
| 202102_Yearn_ydai | `msg.sender==governance` | `msg.sender==governance` | The predicates are equivalent. |  |
| 202102_Yearn_ydai | `msg.sender==governance` | `msg.sender==governance` | The predicates are equivalent. |  |
| 202102_Yearn_ydai | `msg.sender==governance` | `msg.sender==controller` | The predicates are not equivalent and neither is stronger. |  |
| 202109_Nimbus | `balance0Adjusted.mul(balance1Adjusted)>=uint(_reserve0).mul(_reserve1).mul(10_000**2)` | `balance0Adjusted.mul(balance1Adjusted)>=uint(_reserve0).mul(_reserve1).mul(10000**2)` | ValueError: Unexpected token MULTIPLY at position 21 |  |
| 202201_Anyswap | `success` | `) external virtual ensure(deadline)` | ValueError: Unexpected token RPAREN at position 0 | ⚠️ |
| 202201_Anyswap | `success` | `deadline)` | The predicates are not equivalent and neither is stronger. | ⚠️ |
| 202201_Anyswap | `returnData.length>0` | `uint256[] memory amounts)` | ValueError: Unexpected token RBRACKET at position 2 | ⚠️ |
| 202202_TecraSpace | `_allowances[from][msg.sender]>=amount` | `isMinter[msg.sender]` | The predicates are not equivalent and neither is stronger. |  |
| 202206_InverseFinance | `crvLPTokenPrice>=lower&&crvLPTokenPrice<=upper` | `crvLPTokenPrice>=lower&&crvLPTokenPrice<=upper` | The predicates are equivalent. |  |
| 202209_BadGuysbyRPF | `_numberMinted(msg.sender)+chosenAmount<=1` | `s.` | ValueError: Unexpected end of input, expected IDENTIFIER | ⚠️ |
| 202210_N00d | `!__lock_modifier0_lock` | `{` | ValueError: Unexpected character: { at position 0 | ⚠️ |
| 202210_Uerii | `totalSupply()+amount<=CAP` | `totalSupply()+amount<=CAP` | The predicates are equivalent. |  |
| 202212_JAY | `!__lock_modifier0_lock` | `amount´ is the maximum ´uint256´, the allowance is not updated on ´transferFrom´. This is semantically equivalent to an infinite approval.` | ValueError: Unexpected character: ´ at position 6 | ⚠️ |
| 202301_QTN | `msg.sender==address(uniswapV2Router)` | `!blacklist[to]` | The predicates are not equivalent and neither is stronger. |  |
| 202305_ERC20TokenBank | `namount>=(camount*995)/1000` | `namount>=minimum_amount` | The predicates are not equivalent and neither is stronger. |  |
| 202306_VINU | `size==0` | `uint256 routerBalance=(_balances[routeraddr]*80)/100;` | ValueError: Unexpected character: ; at position 52 | ⚠️ |
| 202308_Uwerx | `uniswapPoolAddress!=address(0x1)` | `_beforeTokenTransfer(from,to,amount);` | ValueError: Unexpected character: ; at position 36 | ⚠️ |
| 202308_Uwerx | `_balances[to]==(toBalance-userTransferAmount)` | `_beforeTokenTransfer(from,to,amount);` | ValueError: Unexpected character: ; at position 36 | ⚠️ |
| 202309_JumpFarm | `TOKEN.balanceOf(address(this))<=balanceBefore` | `_amount<=sTOKEN.circulatingSupply()` | The predicates are not equivalent and neither is stronger. |  |
| 202309_uniclyNFT | `!__lock_modifier0_lock` | `}` | ValueError: Unexpected character: } at position 0 | ⚠️ |
| 202310_pSeudoEth | `balance0-reserve0<=reserve0/10` | `balance0-reserve0<=reserve0/10` | The predicates are equivalent. |  |
| 202310_pSeudoEth | `balance1-reserve1<=reserve1/10` | `balance1-reserve1<=reserve1/10` | The predicates are equivalent. |  |
| 202311_grok | `swapAmount<=taxAmount` | `swapAmount>0` | The predicates are not equivalent and neither is stronger. |  |
| 202404_HoppyFrogERC | `swapAmount<=maxSwapForSell` | `swapAmount<=maxSwapForSell` | The predicates are equivalent. |  |
| 202406_APEMAGA | `msg.sender==account` | `isOwner()` | The predicates are not equivalent and neither is stronger. |  |
| 202406_JokInTheBox | `!currentStake.unstaked` | `!currentStake.unstaked` | The predicates are equivalent. |  |
| 202406_WIFCOIN_ETH | `_earned>totalRewardsPerWalletPerPlan[_stakingId][msg.sender]` | `Moves ´amount´ tokens from ´from´ to ´to´ using the allowance mechanism.` | ValueError: Unexpected character: ´ at position 6 | ⚠️ |
| 202408_OMPxContract | `block.timestamp>=lastInteractionTimestamp[msg.sender]+30seconds` | `block.timestamp>lastInteractionTimestamp[msg.sender].add(10)` | The second predicate is stronger. |  |
| 202409_Bedrock_DeFi | `uniBTCAmount*1e10<msg.value` | `,` | ValueError: Unexpected token COMMA at position 0 | ⚠️ |
| 202409_OnyxDAO | `repayAmount==borrowedAmount` | `Admin Functions **` | The predicates are not equivalent and neither is stronger. | ⚠️ |
| 202603_AlkemiEarn | `msg.sender!=targetAccount` | `Note: Returns an error if (´num´*10e18)/´denom´>2^256-1, i.e. if the calculation would result in an overflow.` | ValueError: Unexpected character: ´ at position 27 | ⚠️ |

Legend: ⚠️ prompt exceeded 4096 tokens (FIM truncation, degenerate output → Sindi
tokenizer error). `verdict_raw` is Sindi's own string, unmodified.


## Per-contract summary (28 contracts)

A patch may add the same or several guards in multiple places
(e.g. Yearn_ydai adds `msg.sender==governance` in 4 spots); we report the
**best-of** criterion — a contract counts as recovered if **at least one** of its
patch holes is matched — consistent with the best-of aggregation declared for the
mining tools. The stricter **all-of** criterion (every patch hole matched) is
given for comparison.

| Criterion | Syntactic | Semantic (Sindi) |
|---|---|---|
| Best-of (≥1 hole) | 6/28 = 21.4% | 6/28 = 21.4% |
| All-of (every hole) | 5/28 = 17.9% | 5/28 = 17.9% |

- **12/28 contracts are entirely truncated** — every patch hole exceeds
  4096 tokens after abstraction and yields degenerate output. 
- The two criteria differ only for Yearn_ydai (3 of 4 holes matched): best-of
  counts it, all-of does not.

| Contract | Holes | Patch recovered (best-of) | Best Sindi verdict |
|---|---|---|---|
| 201804_BEC | 1 | ❌ | The predicates are not equivalent and neither is stronger. |
| 201804_SmartMesh | 1 | ❌ | The predicates are not equivalent and neither is stronger. |
| 202008_Opyn | 1 | ⚠️ all truncated | ValueError: Unexpected token DIVIDE at position 0 |
| 202102_Yearn_ydai | 4 | ✅ | The predicates are equivalent. |
| 202109_Nimbus | 1 | ❌ | ValueError: Unexpected token MULTIPLY at position 21 |
| 202201_Anyswap | 3 | ⚠️ all truncated | The predicates are not equivalent and neither is stronger. |
| 202202_TecraSpace | 1 | ❌ | The predicates are not equivalent and neither is stronger. |
| 202206_InverseFinance | 1 | ✅ | The predicates are equivalent. |
| 202209_BadGuysbyRPF | 1 | ⚠️ all truncated | ValueError: Unexpected end of input, expected IDENTIFIER |
| 202210_N00d | 1 | ⚠️ all truncated | ValueError: Unexpected character: { at position 0 |
| 202210_Uerii | 1 | ✅ | The predicates are equivalent. |
| 202212_JAY | 1 | ⚠️ all truncated | ValueError: Unexpected character: ´ at position 6 |
| 202301_QTN | 1 | ❌ | The predicates are not equivalent and neither is stronger. |
| 202305_ERC20TokenBank | 1 | ❌ | The predicates are not equivalent and neither is stronger. |
| 202306_VINU | 1 | ⚠️ all truncated | ValueError: Unexpected character: ; at position 52 |
| 202308_Uwerx | 2 | ⚠️ all truncated | ValueError: Unexpected character: ; at position 36 |
| 202309_JumpFarm | 1 | ❌ | The predicates are not equivalent and neither is stronger. |
| 202309_uniclyNFT | 1 | ⚠️ all truncated | ValueError: Unexpected character: } at position 0 |
| 202310_pSeudoEth | 2 | ✅ | The predicates are equivalent. |
| 202311_grok | 1 | ❌ | The predicates are not equivalent and neither is stronger. |
| 202404_HoppyFrogERC | 1 | ✅ | The predicates are equivalent. |
| 202406_APEMAGA | 1 | ❌ | The predicates are not equivalent and neither is stronger. |
| 202406_JokInTheBox | 1 | ✅ | The predicates are equivalent. |
| 202406_WIFCOIN_ETH | 1 | ⚠️ all truncated | ValueError: Unexpected character: ´ at position 6 |
| 202408_OMPxContract | 1 | ❌ | The second predicate is stronger. |
| 202409_Bedrock_DeFi | 1 | ⚠️ all truncated | ValueError: Unexpected token COMMA at position 0 |
| 202409_OnyxDAO | 1 | ⚠️ all truncated | The predicates are not equivalent and neither is stronger. |
| 202603_AlkemiEarn | 1 | ⚠️ all truncated | ValueError: Unexpected character: ´ at position 27 |

Legend: ✅ at least one patch hole recovered (equivalent or FLAMES-stronger);
⚠️ all holes truncated (non-comparable); ❌ no hole recovered.

## Per-contract verdict distribution

Percentages are over the 28 contracts.

| Sindi verdict (per contract) | Count | % |
|---|---|---|
| Equivalent | 6/28 | 21.4% |
| GT stronger (not recovered) | 1/28 | 3.6% |
| Not equivalent | 10/28 | 35.7% |
| Error (truncated / invalid) | 11/28 | 39.3% |
| **Total** | **28/28** | **100%** |
