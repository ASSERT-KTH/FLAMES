// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SharedStruct.sol";

contract Pool {
    using SharedStruct for SharedStruct.Pool;

    address public mainContract;

    SharedStruct.Pool[] public allPools;
    mapping(uint => uint[]) public numberDumpPerPool;
    mapping(uint => mapping(uint => uint)) private numberCount;
    mapping(uint => uint[]) private uniqueNumbers;

    modifier isMainContract() {
        require(msg.sender == mainContract, "You called this contract directly.");
        _;
    }

    modifier poolExists(uint _poolId) {
        require(isPool(_poolId), "There is no pool with this index.");
        _;
    }

    constructor(address _mainContract) {
        mainContract = _mainContract;
    }

    function isPool(uint poolIdx) public view returns (bool) {
        return poolIdx < allPools.length;
    }

    function getPool(uint poolIdx) public view poolExists(poolIdx) returns (SharedStruct.Pool memory) {
        return allPools[poolIdx];
    }

    function canPurchase(uint poolIdx) public view poolExists(poolIdx) returns (bool) {
        SharedStruct.Pool memory pool = allPools[poolIdx];
        return block.timestamp < pool.joiningPeriodEnd;
    }

    function canActivate(uint poolIdx) public view poolExists(poolIdx) returns (bool) {
        SharedStruct.Pool memory pool = allPools[poolIdx];
        return block.timestamp > pool.joiningPeriodEnd && block.timestamp < pool.activationPeriodEnd;
    }

    function createPool(address creator, uint8 multiplier, uint winnableAmount, uint joiningEnd, uint activationEnd) public isMainContract {
        SharedStruct.Pool memory newPool;
        newPool.idx = allPools.length;
        newPool.amountWinnable = winnableAmount;
        newPool.winner = address(0);
        newPool.lowestUniqueNumber = 1_000_000;
        newPool.claimed = false;
        newPool.joiningPeriodEnd = joiningEnd;
        newPool.activationPeriodEnd = activationEnd;
        newPool.creator = creator;
        newPool.ticketsSold = 0;
        newPool.multiplier = multiplier;
        allPools.push(newPool);
    }

    function getAllPools() public view returns (SharedStruct.Pool[] memory) {
        return allPools;
    }

    function getTicketCount(uint poolIdx) public view poolExists(poolIdx) returns (uint) {
        return allPools[poolIdx].ticketsSold;
    }

    function addNumbers(uint poolIdx, uint32[] memory data) public isMainContract poolExists(poolIdx) {
        for (uint8 idx = 0; idx < data.length; idx++) {
            uint32 currNumber = data[idx];
            if (currNumber > 0 && currNumber < 1_000_000) {
                numberDumpPerPool[poolIdx].push(currNumber);
                numberCount[poolIdx][currNumber]++;
                if (numberCount[poolIdx][currNumber] == 1) {
                    uniqueNumbers[poolIdx].push(currNumber);
                }
            }
        }
    }

    function getNumberDumpForPool(uint256 poolIdx) public view poolExists(poolIdx) returns (uint256[] memory) {
        SharedStruct.Pool memory pool = allPools[poolIdx];
        require(block.timestamp > pool.joiningPeriodEnd, "There is no activation of tickets yet");
        return numberDumpPerPool[poolIdx];
    }

    function setLowestUniqueNumber(uint256 poolIdx) public poolExists(poolIdx) {
        SharedStruct.Pool storage pool = allPools[poolIdx];
        require(block.timestamp > pool.activationPeriodEnd, "Activation period has not ended yet.");
        require(pool.lowestUniqueNumber == 1_000_000, "Lowest number has already been calculated.");
        uint256 lowestNumber = pool.lowestUniqueNumber;
        for (uint256 idx = 0; idx < uniqueNumbers[poolIdx].length; idx++) {
            if (numberCount[poolIdx][uniqueNumbers[poolIdx][idx]] == 1 && uniqueNumbers[poolIdx][idx] < lowestNumber) {
                lowestNumber = uniqueNumbers[poolIdx][idx];
            }
        }
        pool.lowestUniqueNumber = lowestNumber;
    }

    function getLowestUniqueNumber(uint poolIdx) public view poolExists(poolIdx) returns (uint) {
        SharedStruct.Pool memory pool = allPools[poolIdx];
        return pool.lowestUniqueNumber;
    }

    function addPurchaseData(uint poolIdx, uint totalNumbers, uint addToPool) public isMainContract poolExists(poolIdx) {
        SharedStruct.Pool storage pool = allPools[poolIdx];
        pool.ticketsSold += totalNumbers;
        pool.amountWinnable += addToPool;
    }

    function setWinner(address winner, uint poolIdx) public isMainContract poolExists(poolIdx) {
        SharedStruct.Pool storage pool = allPools[poolIdx];
        pool.winner = winner;
    }

    function setAsClaimed(uint poolIdx) public isMainContract poolExists(poolIdx) {
        SharedStruct.Pool storage pool = allPools[poolIdx];
        pool.claimed = true;
    }

    function checkWinner(uint poolIdx, uint claimingPeriodEnd) public view isMainContract poolExists(poolIdx) {
        SharedStruct.Pool memory pool = allPools[poolIdx];
        require(block.timestamp > pool.activationPeriodEnd, "Activation period has not ended yet.");
        require(block.timestamp < (pool.activationPeriodEnd + claimingPeriodEnd), "Claiming window has ended");
        require(!pool.claimed, "This pool has already been claimed.");
        require(pool.lowestUniqueNumber < 1_000_000, "There is no winner.");
    }
}