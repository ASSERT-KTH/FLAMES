// SPDX-License-Identifier: MIT

// RavenFund - $RAVEN
//
// The raven symbolizes prophecy, insight, transformation, and intelligence. It also represents long-term success.
// The 1st AI-powered hedge fund
//
// https://www.ravenfund.app/
// https://twitter.com/RavenFund
// https://t.me/RavenFundPortal

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RavenFundPresale is Ownable {
    uint256 public startTime;
    uint256 public endTime;
    bool public presaleStarted = false;

    struct TransactionHistory {
        address addressParticipant;
        uint256 amountEth;
        uint256 timestampBuy;
    }
    
    mapping(address => bool) private isParticipant;

    mapping(address => uint256) private participantDepositEth;

    TransactionHistory[] private transactionHistory;
    address public tokenContract;

    address[] public participants;

    constructor() {
    }
    
    modifier onlyWhileOpen() {
        require(presaleStarted, "Presale is not open");
        _;
    }
    
    function startPresale() external onlyOwner {
        startTime = block.timestamp;
        presaleStarted = true;
    }
    
    
    function stopPresale() external onlyOwner {
        endTime = block.timestamp;
        presaleStarted = false;
    }
    
    function participatePresale() external payable onlyWhileOpen {
        require(msg.value >= 0.1 ether && msg.value <= 2 ether, "Invalid ETH amount");
        require((participantDepositEth[msg.sender] + msg.value) <= 2 ether, "You cannot buy more than 2 eth");
        require((address(this).balance + msg.value) <= 100 ether, "Hardcap set to 100 eth");

        if (!isParticipant[msg.sender]) {
            isParticipant[msg.sender] = true;
            participants.push(msg.sender);
        }

        participantDepositEth[msg.sender] += msg.value;

        transactionHistory.push(TransactionHistory({
            addressParticipant:msg.sender,
            amountEth: msg.value,
            timestampBuy: block.timestamp
        }));
    }
    
    function getParticipants() external view onlyOwner returns (address[] memory, uint256[] memory) {
        uint256 length = participants.length;
        uint256[] memory ethBought = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            ethBought[i] = participantDepositEth[participants[i]];
        }

        return (participants, ethBought);
    }

    function getAllTransactions() external view onlyOwner returns (TransactionHistory[] memory) {
        return transactionHistory;
    }

    function setOfficialContract(address adr) external onlyOwner {
        tokenContract = adr;
    }

    function getDepositParticipant() external view returns (uint256) {
        return participantDepositEth[msg.sender];
    }

    function getStartTime() external view returns (uint256) {
        return startTime;
    }

    function getEndTime() external view returns (uint256) {
        return endTime;
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }
}