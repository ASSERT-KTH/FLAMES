# FLAMES Invariant Synthesis Results

This table compares the ground-truth invariant from each contract's `diff.diff`
against the invariant synthesized by FLAMES (FLAMES-100k model
applied to the patch contract).

**Methodology**: For each contract, the patch contract (`*_patch.sol`) was fed to
FLAMES. Every `require()` statement was masked one at a time with a Fill-In-the-Middle
prompt (`▁<PRE>...▁<SUF>...▁<MID>`). The synthesized output was compared against the
ground-truth predicate from the diff.

| Contract | Ground-truth invariant (from diff) | FLAMES synthesized invariant | Match |
|---|---|---|---|
| 201804_BEC | `require(_value <= uint256(-1) / cnt)` | `_value<=balances[msg.sender]` | ❌ |
| 201804_SmartMesh | `require(total >= _feeSmt && total >= _value)` | `extraData)) revert()` | ❌ |
| 202008_Opyn | `require(msg.value == underlyingRequiredToExercise(oTokensToExercise), "Incorrect msg.value")` | `"Other implementations of the EIP may not emit"` | ❌ |
| 202102_Yearn_ydai | `require(msg.sender == governance, "only governance can call earn()")` | `",newAllowance)"` | ❌ |
| 202109_Nimbus | `require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(10_000**2), 'Nimbus: K')` | `}` | ❌ |
| 202201_Anyswap | `require(v == 27 \|\| v == 28, "Router: bad v")` | `bytes32 s` | ❌ |
| 202202_TecraSpace | `require(_allowances[from][msg.sender] >= amount, ERROR_ATL)` | `//` | ❌ |
| 202206_InverseFinance | `require(crvLPTokenPrice >= lower && crvLPTokenPrice <= upper, "LP price deviates from Curve VP")` | `crvLPTokenPrice>=lower&&crvLPTokenPrice<=upper` | ✅ |
| 202209_BadGuysbyRPF | `require(_numberMinted(msg.sender) + chosenAmount <= 1, "Mint limit exceeded")` | `Id\` token from \`from\` to \`to\`.` | ❌ |
| 202210_N00d | `require(!__lock_modifier0_lock, "ReentrancyGuard: function is already executing")` | `73b7bfad8045d85a470 is returned for accounts without code` | ❌ |
| 202210_Uerii | `require(totalSupply() + amount <= CAP, "Invariant violation: cap exceeded")` | `address spender,` | ❌ |
| 202212_JAY | `require(!__lock_modifier0_lock, "ReentrancyGuard: function is already executing")` | `(` | ❌ |
| 202301_QTN | `require(msg.sender == address(uniswapV2Router), "rebase denied, unauthorized caller (possible skim)")` | `56 amount) public override returns (bool) {` | ❌ |
| 202305_ERC20TokenBank | `require(namount >= (camount * 995) / 1000, "slippage too high")` | `namount>=minimum_amount` | ❌ (close) |
| 202306_VINU | `require(size == 0, "Invalid devaddr: cannot be a contract")` | `function allowance(` | ❌ |
| 202308_Uwerx | `uniswapPoolAddress!=address(0x1)` `_balances[to]==(toBalance-userTransferAmount)` | `/10**2).` `/10**2).` | ❌ |
| 202309_JumpFarm | `require(TOKEN.balanceOf(address(this)) <= balanceBefore,"Invariant: rebase must not increase balance mid-unstake");` | `Distribute rewards to stakers` | ❌ |
| 202309_uniclyNFT | `require(!__lock_modifier0_lock, "ReentrancyGuard: function is already executing")` | `>=0.6.2<0.8.0;` | ❌ |
| 202310_pSeudoEth | `require(balance0 - reserve0 <= reserve0 / 10, "UniswapV2: EXCESSIVE_IMBALANCE_TOKEN0")` `require(balance1 - reserve1 <= reserve1 / 10, "UniswapV2: EXCESSIVE_IMBALANCE_TOKEN1")` | `{ {` | ❌ |
| 202311_grok | `require(swapAmount <= taxAmount)` | `address(this);` | ❌ |
| 202404_HoppyFrogERC | `require(swapAmount <= maxSwapForSell, "Autoswap exceeds tax-scaled cap")` | `(contractETHBalance>0)` | ❌ |
| 202406_APEMAGA | `require(msg.sender == account, "Unauthorized: caller is not the token owner")` | `msg.sender==account` | ✅ |
| 202406_JokInTheBox | `require(!currentStake.unstaked, "Stake has already been unstaked!")` | `: 10` | ❌ |
| 202406_WIFCOIN_ETH | `require(_earned > totalRewardsPerWalletPerPlan[_stakingId][msg.sender], "Rewards already claimed")` | `require(success,"Address: unable to send value, recipient may have reverted")` | ❌ |
| 202408_OMPxContract | `require(block.timestamp >= lastInteractionTimestamp[msg.sender] + 30 seconds)` | `token = OMPxToken(0x000...000)` | ❌ |
| 202409_Bedrock_DeFi | `require(uniBTCAmount * 1e10 < msg.value, "SYS008: Exchange rate unsafe")` | `igence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].` | ❌ |
| 202409_OnyxDAO | `require(repayAmount == borrowedAmount, "Repay amount must be exactly what the borrower owes")` | `if(a==0)return 0;` | ❌ |
| 202603_AlkemiEarn | `require(msg.sender != targetAccount, "self-liquidation is not possible");` | `ILED,` | ❌ |

## Summary

| Result | Count | % |
|---|---|---|
| Exact match | 2 | 7.1% |
| Garbage output (context truncation) | 24 | 85.67% |
| Wrong but non-garbage | 2 | 7.1% |
| **Total** | **28** | **100%** |
