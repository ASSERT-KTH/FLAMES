// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SpawnerV2 } from './Spawner.sol';
import { IPondCoinSpawner } from '../PondCoin.sol';
import { IMiningPerCycle } from './IMiningPerCycle.sol';
import { ISpawnManager } from './ISpawnManager.sol';
import { ExecutorManager } from '../Helpers/ExecutorManager.sol';
import { SpawnConfigurationParams } from './SpawnConfigurationParams.sol';

contract SpawnManagerV2 is ISpawnManager, ExecutorManager {
    event SpawnCreated(address indexed spawnContract, uint256 createdIndex);

    error InvalidSpawnIndex();
    error NotSetup();

    uint256 public spawnIndex;
    mapping(uint256 => SpawnerV2) public spawners;

    SpawnConfigurationParams public configuration;

    bool public setup = false;

    IERC20 public spawnedCoin;
    IERC20 public spawnedFromCoin;

    constructor(IERC20 _spawnedCoin, IERC20 _spawnedFromCoin) {
        _addExecutor(msg.sender);
        spawnedCoin = _spawnedCoin;
        spawnedFromCoin = _spawnedFromCoin;
    }

    function readConfiguration() external view returns (SpawnConfigurationParams memory) {
        return(configuration);
    }

    modifier validSpawnIndex(uint256 index) {
        if (index == 0 || index > spawnIndex) revert InvalidSpawnIndex();
        _;
    }

    modifier onlyWhenSetup() {
        if (!setup) revert NotSetup();
        _;
    }

    function updateConfiguration(SpawnConfigurationParams calldata _configuration) onlyExecutor external {
        setup = true;
        configuration = _configuration;
    }

    function deposit(IERC20 token, uint256 amount) external onlyExecutor() {
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(IERC20 token, uint256 amount) external onlyExecutor() {
        token.transfer(msg.sender, amount);
    }

    function createSpawn(uint256 spawnAmount) onlyWhenSetup onlyExecutor external {
        SpawnerV2 createdSpawner = new SpawnerV2(
            configuration.miningChecker.cycleIndex(),
            spawnAmount,
            spawnedCoin,
            spawnedFromCoin,
            configuration
        );

        spawnedCoin.approve(address(createdSpawner), type(uint256).max);

        uint256 newIndex = ++spawnIndex; 

        spawners[newIndex] = createdSpawner;

        require(createdSpawner.isExecutor(address(this)), 'NXC');

        emit SpawnCreated(address(createdSpawner), newIndex);
    }

    function getSpawner(uint256 index) validSpawnIndex(index) external view returns (address) {
        return(address(spawners[index]));
    }

    function end(uint256 index) validSpawnIndex(index) onlyExecutor external {
        spawners[index].end();
    }

    function spawnThrough(uint256 _spawnerIndex, uint256 _amount) external returns(uint256 spawnAmount) {
        require(spawnedFromCoin.transferFrom(msg.sender, address(this), _amount));
        return(spawners[_spawnerIndex].executorSpawn(msg.sender, _amount));
    }
}
