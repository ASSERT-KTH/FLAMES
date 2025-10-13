// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SharedStruct.sol";
import "./SharedState.sol";
import "./Pool.sol";
import "./TicketOptions.sol";
import "./Ticket.sol";

contract CipherHub is SharedState {
    using SharedStruct for SharedStruct.TicketOption;
    using SharedStruct for SharedStruct.Pool;

    Pool private poolContract;
    TicketOption private ticketOptionContract;
    Ticket private ticketContract;

    mapping(address => uint) public creatorPayment;
    bool private emergencyStop;
    uint private latestPoolCreatedAt;

    modifier isNotStopped() {
        require(!emergencyStop, "There has been an emergency stop, please stand by for further details.");
        _;
    }

    function changePoolContract(address _poolAddress) public hasAuthority {
        poolContract = Pool(_poolAddress);
    }

    function changeTicketContract(address _ticketAddress) public hasAuthority {
        ticketContract = Ticket(_ticketAddress);
    }

    function changeTicketOptionContract(address _ticketOptionAddress) public hasAuthority {
        ticketOptionContract = TicketOption(_ticketOptionAddress);
    }

    function setEmergencyStop(bool _emergencyStop) public hasAuthority {
        emergencyStop = _emergencyStop;
    }

    function getEmergencyStop() public view returns (bool) {
        return emergencyStop;
    }

    function createTicketOption(uint baseTickets, uint additionalTickets) public hasAuthority {
        ticketOptionContract.createTicketOption(baseTickets, additionalTickets);
    }

    function changeUsabilityTicketOption(uint _ticketOptionIdx, bool newVal) public hasAuthority {
        ticketOptionContract.switchUsabilityTicketOption(_ticketOptionIdx, newVal);
    }

    function createPool(uint8 multiplier) public isNotStopped payable {
        require(msg.value >= baseCreationFee * multiplier, "You did not send enough ETH to create a pool.");
        uint256 joiningEnd = block.timestamp + baseJoiningPeriod;
        uint256 activationEnd = block.timestamp + baseJoiningPeriod + baseActivationPeriod;
        poolContract.createPool(msg.sender, multiplier, msg.value, joiningEnd, activationEnd);
        latestPoolCreatedAt = block.timestamp;
    }

    function purchaseTicket(uint poolIdx, uint8 ticketOptionIdx, string memory encryptedRes, bytes32 hashedRes) public payable {
        SharedStruct.Pool memory chosenpool = poolContract.getPool(poolIdx);
        require(block.timestamp < chosenpool.joiningPeriodEnd, "Joining period has ended for this pool");
        SharedStruct.TicketOption memory ticketOpt = ticketOptionContract.getTicketOptionDetails(ticketOptionIdx);
        require(msg.value >= ticketOpt.baseTickets * chosenpool.multiplier * baseJoiningFee, "You did not send enough ETH.");
        uint totalNumbers = ticketOpt.baseTickets + ticketOpt.additionalTickets;
        uint addToPool = (msg.value / 100 * (100 - poolCreatorFeePercentage - cipherHubFeePercentage));
        ticketContract.purchaseTicket(msg.sender, poolIdx, totalNumbers, encryptedRes, hashedRes);
        poolContract.addPurchaseData(poolIdx, totalNumbers, addToPool);
        creatorPayment[chosenpool.creator] += msg.value / 100 * poolCreatorFeePercentage;
        addToManagementPool(msg.value / 100 * cipherHubFeePercentage);
    }

    function activateTicket(uint poolIdx, uint ticketIdx, uint8[] memory salt, uint32[] memory data) public {
        require(poolContract.canActivate(poolIdx), "You're not in the activation period.");
        SharedStruct.Ticket memory ticket = ticketContract.getTicketByIdx(msg.sender, poolIdx, ticketIdx);
        uint32[] memory dataBasedOnTicketCount = new uint32[](ticket.numberCount);
        for (uint i = 0; i < ticket.numberCount; i++) {
            dataBasedOnTicketCount[i] = data[i];
        }
        ticketContract.activateTicket(msg.sender, poolIdx, ticketIdx, salt, data, dataBasedOnTicketCount);
        poolContract.addNumbers(poolIdx, dataBasedOnTicketCount);
    }

    function claimWinningEth(uint poolIdx) public nonReentrant {
        poolContract.checkWinner(poolIdx, claimingPeriodEnd);
        SharedStruct.Pool memory pool = poolContract.getPool(poolIdx);
        require(ticketContract.validateWinner(msg.sender, poolIdx, pool.lowestUniqueNumber), "You do not have the winning number");
        poolContract.setWinner(msg.sender, poolIdx);
        (bool success,) = payable(msg.sender).call{value: pool.amountWinnable}("");
        require(success, "Claiming failed");
        poolContract.setAsClaimed(poolIdx);
    }

    function claimAsPoolCreator() public nonReentrant {
        require(creatorPayment[msg.sender] > 0, "There is nothing to claim");
        (bool success,) = payable(msg.sender).call{value: creatorPayment[msg.sender]}("");
        require(success, "Claiming failed");
        creatorPayment[msg.sender] = 0;
    }

    function claimAsCipherHub(uint poolIdx) public hasAuthority nonReentrant {
        SharedStruct.Pool memory pool = poolContract.getPool(poolIdx);
        require(!pool.claimed, "This pool has already been claimed.");
        require(block.timestamp > (pool.activationPeriodEnd + claimingPeriodEnd), "Claiming period has not ended yet.");
        (bool success,) = payable(msg.sender).call{value: pool.amountWinnable}("");
        require(success, "Claiming failed");
        poolContract.setAsClaimed(poolIdx);
    }

    function claimLastResort() public hasAuthority nonReentrant {
        uint halfYear = 3 * 30 days;
        require(block.timestamp > (latestPoolCreatedAt + halfYear), "There are still pools being created.");
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Claiming failed");
    }
}