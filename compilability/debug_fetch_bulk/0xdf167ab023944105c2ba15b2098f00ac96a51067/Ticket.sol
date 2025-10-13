// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SharedStruct.sol";

contract Ticket {
    using SharedStruct for SharedStruct.Ticket;

    mapping(address => mapping(uint => SharedStruct.Ticket[])) private addressTickets;
    address public mainContract;

    modifier isMainContract() {
        require(msg.sender == mainContract, "You called this contract directly.");
        _;
    }

    modifier ticketExists(address buyer, uint poolIdx, uint ticketIdx) {
        require(ticketIdx < addressTickets[buyer][poolIdx].length, "There is no such ticket");
        _;
    }

    constructor(address _mainContract) {
        mainContract = _mainContract;
    }

    function getTicketByIdx(address buyer, uint poolIdx, uint ticketIdx) public view ticketExists(buyer, poolIdx, ticketIdx) returns (SharedStruct.Ticket memory) {
        return addressTickets[buyer][poolIdx][ticketIdx];
    }

    function getNewTicket(uint poolIdx, uint ticketIdx) public view ticketExists(msg.sender, poolIdx, ticketIdx) returns (SharedStruct.Ticket memory) {
        return addressTickets[msg.sender][poolIdx][ticketIdx];
    }

    function getMyTickets(uint poolIdx) public view returns (SharedStruct.Ticket[] memory){
        return addressTickets[msg.sender][poolIdx];
    }

    function getMyTicketCount(uint poolIdx) public view returns (uint) {
        return addressTickets[msg.sender][poolIdx].length;
    }

    function purchaseTicket(address buyer, uint poolIdx, uint _numberCount, string memory encryptedRes, bytes32 hashedRes) public isMainContract {
        SharedStruct.Ticket memory newTicket;
        newTicket.idx = addressTickets[buyer][poolIdx].length;
        newTicket.numberCount = _numberCount;
        newTicket.encryptedData = encryptedRes;
        newTicket.hashedData = hashedRes;
        newTicket.activated = false;
        addressTickets[buyer][poolIdx].push(newTicket);
    }

    function activateTicket(address buyer, uint poolIdx, uint ticketIdx, uint8[] memory salt, uint32[] memory data, uint32[] memory dataBasedOnTicketCount) public isMainContract ticketExists(buyer, poolIdx, ticketIdx) {
        SharedStruct.Ticket storage ticketToActivate = addressTickets[buyer][poolIdx][ticketIdx];
        require(!ticketToActivate.activated, "This ticket has already been activated.");
        require(ticketToActivate.hashedData == keccak256(abi.encodePacked(salt, data)), "The data does not match.");
        ticketToActivate.activated = true;
        ticketToActivate.unlockedValues = dataBasedOnTicketCount;
    }

    function validateWinner(address buyer, uint poolIdx, uint lowestNumber) public view isMainContract returns (bool){
        bool isWinner;
        SharedStruct.Ticket[] memory ticketLst = addressTickets[buyer][poolIdx];
        for (uint idx = 0; idx < ticketLst.length; idx++) {
            SharedStruct.Ticket memory ticket = ticketLst[idx];
            if (ticket.activated) {
                for (uint numberIdx = 0; numberIdx < ticket.unlockedValues.length; numberIdx++) {
                    if (ticket.unlockedValues[numberIdx] == lowestNumber) {
                        isWinner = true;
                        break;
                    }
                }
            }
        }
        return isWinner;
    }
}
