// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library SharedStruct {
    struct FeeOverview {
        uint creationFee;
        uint joiningFee;
        uint joiningPeriod;
        uint activationPeriod;
        uint claimingPeriodEnd;
    }

    struct Ticket {
        uint idx;
        uint numberCount;
        string encryptedData;
        bytes32 hashedData;
        bool activated;
        uint32[] unlockedValues;
    }

    struct TicketOption {
        uint idx;
        uint baseTickets;
        uint additionalTickets;
        bool active;
    }

    struct Pool {
        uint idx;
        uint joiningPeriodEnd;
        uint activationPeriodEnd;
        uint amountWinnable;
        uint lowestUniqueNumber;
        uint ticketsSold;
        uint8 multiplier;
        address creator;
        address winner;
        bool claimed;
    }
}