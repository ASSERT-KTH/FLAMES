# Frontier-model Invariant Fill Results

Ground truth: condition of the require/assert added by the patch (diff.diff) of each dfhl-invariants contract.

Method: the patched contract is hollowed out by replacing the require line with require(<FILL_ME>);, then the model (gpt:gpt-4o) generates the invariant. Syntactic verdict is determined using FLAMES logic (Evaluation.ipynb: equality ignoring spaces, split on , and )).

For each contract: *_fillme_L<line>.sol (with the hole) and *_patched_L<line>.sol (with the generated invariant).


## Summary

- Total holes: **31**
- Valid generations: **30** (empy/error: 1)
- Exact match (syntactic, FLAMES rules): **10/30 (33.3%)**

## Tabella completa

| Contratto | Riga | Ground truth (dal diff) | Invariante generato | Match |
|---|---|---|---|---|
| 201804_BEC | 288 | `_value <= uint256(-1) / cnt` | `amount / cnt == _value` | ❌ |
| 201804_SmartMesh | 213 | `total >= _feeSmt && total >= _value` | `balances[_from] >= total` | ❌ |
| 202008_Opyn | 1475 | `msg.value == underlyingRequiredToExercise(oTokensToExercise)` | `msg.value == underlyingRequiredToExercise(oTokensToExercise)` | ✅ |
| 202102_Yearn_ydai | 296 | `msg.sender == governance` | `_min <= max` | ❌ |
| 202109_Nimbus | 405 | `balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(10_000**2)` | `balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(10000**2)` | ❌ |
| 202201_Anyswap | 237 | `success` | `success` | ✅ |
| 202201_Anyswap | 481 | `returnData.length > 0` | `success && (returnData.length == 0 \|\| abi.decode(returnData, (bool)))` | ❌ |
| 202202_TecraSpace | 158 | `_allowances[from][msg.sender] >= amount` | `_balances[from] >= amount && _allowances[from][msg.sender] >= amount` | ❌ |
| 202206_InverseFinance | 145 | `crvLPTokenPrice >= lower && crvLPTokenPrice <= upper` | `crvLPTokenPrice >= lower && crvLPTokenPrice <= upper` | ✅ |
| 202209_BadGuysbyRPF | 1194 | `_numberMinted(msg.sender) + chosenAmount <= 1` | `balanceOf(msg.sender) + chosenAmount <= 2` | ❌ |
| 202210_N00d | 853 | `!__lock_modifier0_lock` | `!__lock_modifier0_lock` | ✅ |
| 202210_Uerii | 532 | `totalSupply() + amount <= CAP` | `_totalSupply + amount <= CAP` | ❌ |
| 202212_JAY | 1041 | `!__lock_modifier0_lock` | `!__lock_modifier0_lock` | ✅ |
| 202301_QTN | 292 | `msg.sender == address(uniswapV2Router)` | `balanceOf(to).add(amount) <= _totalSupply.mul(_percentForTxLimit).div(100)` | ❌ |
| 202305_ERC20TokenBank | 258 | `namount >= (camount * 995) / 1000` | `namount >= minimum_amount` | ❌ |
| 202306_VINU | 588 | `size == 0` | `size == 0` | ✅ |
| 202308_Uwerx | 520 | `uniswapPoolAddress!=address(0x1)` | `to == uniswapPoolAddress && amount > 0` | ❌ |
| 202308_Uwerx | 535 | `_balances[to]==(toBalance - userTransferAmount)` | `burnAmount + userTransferAmount + marketingAmount == amount` | ❌ |
| 202309_JumpFarm | 345 | `TOKEN.balanceOf(address(this)) <= balanceBefore` | `TOKEN.balanceOf(address(this)) >= _amount` | ❌ |
| 202309_uniclyNFT | 1471 | `!__lock_modifier0_lock` | `!__lock_modifier0_lock` | ✅ |
| 202310_pSeudoEth | 544 | `balance0 - reserve0 <= reserve0 / 10` | `balance0 - reserve0 <= reserve0 / 10` | ✅ |
| 202310_pSeudoEth | 545 | `balance1 - reserve1 <= reserve1 / 10` | `balance1 - reserve1 <= reserve1 / 10` | ✅ |
| 202311_grok | 250 | `swapAmount <= taxAmount` | `swapAmount <= contractTokenBalance` | ❌ |
| 202404_HoppyFrogERC | 260 | `swapAmount <= maxSwapForSell` | `maxSwapForSell >= swapAmount` | ❌ |
| 202406_APEMAGA | 255 | `msg.sender == account` | `_owner == account` | ❌ |
| 202406_JokInTheBox | 422 | `!currentStake.unstaked` | `!currentStake.unstaked` | ✅ |
| 202406_WIFCOIN_ETH | 979 | `_earned > totalRewardsPerWalletPerPlan[_stakingId][msg.sender]` | `_balanceOf(address(this)) >= _earned.sub(_earned.mul(_burnRate).div(100))` | ❌ |
| 202408_OMPxContract | 378 | `block.timestamp >= lastInteractionTimestamp[msg.sender] + 30 seconds` | `block.timestamp >= lastInteractionTimestamp[msg.sender] + 1 days` | ❌ |
| 202409_Bedrock_DeFi | 2403 | `uniBTCAmount * 1e10 < msg.value` | `!paused[NATIVE_BTC] && msg.value > 0 && msg.value / EXCHANGE_RATE_BASE > 0 && ISupplyFeeder(supplyFeeder).totalSupply(NATIVE_BTC) + msg.value <= caps[NATIVE_BTC]` | ❌ |
| 202409_OnyxDAO | 794 | `repayAmount == borrowedAmount` | `borrowedAmount <= repayAmount` | ❌ |
| 202603_AlkemiEarn | 3458 | `msg.sender != targetAccount` | `—` | ⚠️ empty due to limited tokens |
