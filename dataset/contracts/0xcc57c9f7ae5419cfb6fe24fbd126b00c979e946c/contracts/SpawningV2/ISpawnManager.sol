// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SpawnConfigurationParams } from './SpawnConfigurationParams.sol';

interface ISpawnManager {
    function readConfiguration() external view returns(SpawnConfigurationParams memory);
    function updateConfiguration(SpawnConfigurationParams calldata config) external;
    function createSpawn(uint256 maxAmount) external;
}
