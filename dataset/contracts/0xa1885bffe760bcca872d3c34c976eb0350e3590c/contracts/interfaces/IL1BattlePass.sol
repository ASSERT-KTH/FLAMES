// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IL1BattlePass {
    enum TxType {
        UNLOCK,
        REROLL
    }

    event EthWithdrawn(address to, uint256 amount);
    event MessageSent(
        uint256 nonce,
        address account,
        uint256 season,
        TxType txType
    );
    event NewSeasonStarted(
        uint256 season,
        uint256 duration,
        uint256 price,
        uint256 maxPaidUnlocks
    );
    event MaxPaidUnlocksSet(uint256 maxUnlocks);
    event ScheduleRollPricesSet(uint256[] rollCounts, uint256[] prices);
    event PriceSet(uint256 season, uint256 price);
    event DstChainIdSet(uint16 chainId);
    event SeasonEndTimestampUpdated(uint256 season, uint256 timestamp);
    event AdapterParamsSet(bytes params);
}
