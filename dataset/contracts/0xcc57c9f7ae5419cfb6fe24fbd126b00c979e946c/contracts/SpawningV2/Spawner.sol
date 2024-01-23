// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IMiningPerCycle } from './IMiningPerCycle.sol';
import { IPondCoinSpawner } from '../PondCoin.sol';
import { MathHelpers } from '../Helpers/MathHelpers.sol';
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SpawnConfigurationParams } from './SpawnConfigurationParams.sol';
import { ExecutorManager } from '../Helpers/ExecutorManager.sol';

contract SpawnerV2 is IPondCoinSpawner, MathHelpers, ReentrancyGuard, ExecutorManager {
    error NotDeployer();
    error CannotComputeZero();
    error IncorrectSpawnFrom();
    error NotOpen();
    error CannotEndWhileOpen();
    error CannotSpawnMore();
    error UnderMinimumSpawn();
    error OverUserMaximumSpawn();

    event V2Spawn(address indexed spawner, uint256 amount);

    bool public ended = false;
    uint256 public currentCycle;
    uint256 public closesAt;
    uint256 public canStillSpawn;
    uint256 public totalSpawnAmount;
    address public debitFrom;

    SpawnConfigurationParams public configuration;

    IERC20 public spawnedCoin;
    IERC20 public spawnedFromCoin;

    mapping(address => uint256) public spawnedPerAddress;

    constructor(uint256 _currentCycle, uint256 _totalSpawnAmount, IERC20 _spawnedCoin, IERC20 _spawnedFromCoin, SpawnConfigurationParams memory _configuration) {
        _addExecutor(msg.sender);
        debitFrom = msg.sender;
        configuration = _configuration;
        currentCycle = _currentCycle;
        closesAt = _configuration.spawnLastsFor + block.timestamp;
        spawnedCoin = _spawnedCoin;
        spawnedFromCoin = _spawnedFromCoin;
        canStillSpawn = _totalSpawnAmount;
        totalSpawnAmount = _totalSpawnAmount;
    }

    function isWithinTimeframe() public view returns(bool) {
        return(block.timestamp <= closesAt);
    }

    function isOpen() public view returns(bool) {
        return(isWithinTimeframe() && !ended);
    }

    function computeRate(uint256 _amount) public view returns(uint256) {
        uint256 computed = _multiplyWithNumerator(_amount, configuration.rewardCoinRateNumerator);

        if(computed <= 0) revert CannotComputeZero();

        return(computed);
    }

    function computeDeltaMultiplierWithAmount(uint256 _delta, uint256 _amount) public view returns(uint256 multiplier) {
        return(
            _multiplyWithNumerator(
                _amount,
                // 1 / ((delta * numerator) + 1)
                (divisionDenominator * divisionDenominator) / ((_delta * configuration.cycleDeltaNumerator) + divisionDenominator)
            )
        );
    }

    function weightMinedAmount(address _spawner) public view returns(uint256 mined) {
        mined = configuration.miningChecker.minedPerCycle(_spawner, currentCycle);

        uint256 deltas = configuration.checkCycleDeltas;
        if (deltas != 0 && currentCycle > 0) {
            for (uint256 i = 1; i < deltas;) {
                if ((currentCycle - i) == 0) {
                    break;
                }

                mined += computeDeltaMultiplierWithAmount(i, configuration.miningChecker.minedPerCycle(_spawner, currentCycle - i));

                unchecked {
                    i++;
                }
            }
        }

        return(mined);
    }

    function computeMaximumToSpawn(address _toCheck) public view returns(uint256) {
        uint256 weighted = weightMinedAmount(_toCheck);

        if (weighted > configuration.globalMaxMined) {
            weighted = configuration.globalMaxMined;
        }

        return(_multiplyWithNumerator(weighted, configuration.maxSpawnAmountNumerator));
    }

    function readSpawnState(address _toCheck) external view returns(uint256 maxSpawn, uint256 alreadySpawned) {
        return(computeMaximumToSpawn(_toCheck), spawnedPerAddress[_toCheck]);
    }

    function readSpawnValue(address _spawner, uint256 _inputValue) public view returns (uint256 value) {
        if (isOpen() != true) revert NotOpen();
        if (_inputValue < configuration.minimumSpawnAmount) revert UnderMinimumSpawn();
        if (_inputValue > canStillSpawn) revert CannotSpawnMore();
        if ((spawnedPerAddress[_spawner] + _inputValue) > computeMaximumToSpawn(_spawner)) revert OverUserMaximumSpawn();
        return(computeRate(_inputValue));
    }


    function _spawn(address _spawner, uint256 _inputValue) internal nonReentrant returns(uint256 spawnAmount) {        
        spawnAmount = readSpawnValue(_spawner, _inputValue);

        canStillSpawn -= spawnAmount;
        spawnedPerAddress[_spawner] += _inputValue;

        require(spawnedCoin.transferFrom(debitFrom, _spawner, spawnAmount), "NXF");

        emit V2Spawn(_spawner, _inputValue);

        return(spawnAmount);
    }

    function executorSpawn(address _address, uint256 _amount) onlyExecutor() external returns(uint256 spawnAmount) {
        return(_spawn(_address, _amount));
    }

    function spawn(address _address, uint256 _amount) external returns(bool) {
        if (msg.sender != address(spawnedFromCoin)) revert IncorrectSpawnFrom();
        _spawn(_address, _amount);
        return(true);
    }

    function end() onlyExecutor() external {
        if (isOpen() == true) revert CannotEndWhileOpen();
        ended = true;
    }
}
