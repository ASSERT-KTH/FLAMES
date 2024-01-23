// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IMiningPerCycle } from './IMiningPerCycle.sol';

struct SpawnConfigurationParams {
    IMiningPerCycle miningChecker;
    uint256 spawnLastsFor;
    uint256 globalMaxMined;
    uint256 maxSpawnAmountNumerator;
    uint256 rewardCoinRateNumerator;
    uint256 checkCycleDeltas;
    uint256 cycleDeltaNumerator;
    uint256 minimumSpawnAmount;
}
