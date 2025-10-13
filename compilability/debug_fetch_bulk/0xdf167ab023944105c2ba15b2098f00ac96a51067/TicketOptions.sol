// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SharedStruct.sol";

contract TicketOption {
    using SharedStruct for SharedStruct.TicketOption;

    SharedStruct.TicketOption[] public allTicketOptions;

    address public mainContract;

    modifier ticketOptionExists(uint _ticketOptionIdx) {
        require(isTicketOption(_ticketOptionIdx), "There is no ticket with this index.");
        _;
    }

    modifier isMainContract() {
        require(msg.sender == mainContract, "You called this contract directly.");
        _;
    }

    constructor(address _mainContract) {
        mainContract = _mainContract;
    }

    function createTicketOption(uint baseTickets, uint additionalTickets) public isMainContract {
        SharedStruct.TicketOption memory ticketOpt;
        ticketOpt.idx = allTicketOptions.length;
        ticketOpt.baseTickets = baseTickets;
        ticketOpt.additionalTickets = additionalTickets;
        ticketOpt.active = true;
        allTicketOptions.push(ticketOpt);
    }

    function isTicketOption(uint ticketIdx) private view returns (bool) {
        return ticketIdx < allTicketOptions.length;
    }

    function isActiveTicketOption(uint ticketIdx) public view ticketOptionExists(ticketIdx) returns (bool) {
        SharedStruct.TicketOption memory ticketOpt = allTicketOptions[ticketIdx];
        return ticketOpt.active;
    }

    function getTicketOptionDetails(uint ticketIdx) public view ticketOptionExists(ticketIdx) returns (SharedStruct.TicketOption memory) {
        require(isActiveTicketOption(ticketIdx), "This ticket is currently unavailable");
        return allTicketOptions[ticketIdx];
    }

    function getAllTicketOptions() public view returns (SharedStruct.TicketOption[] memory) {
        return allTicketOptions;
    }

    function switchUsabilityTicketOption(uint _ticketOptionIdx, bool newVal) public isMainContract ticketOptionExists(_ticketOptionIdx) {
        SharedStruct.TicketOption storage foundTicketOption = allTicketOptions[_ticketOptionIdx];
        foundTicketOption.active = newVal;
    }
}
