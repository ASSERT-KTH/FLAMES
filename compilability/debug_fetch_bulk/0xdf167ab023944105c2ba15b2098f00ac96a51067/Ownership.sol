// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract Ownership {
    uint public managementPool;
    mapping(address => bool) public owners;
    bool private locked;

    modifier hasAuthority() {
        require(verifyOwner(), "You are not authorized to do this action.");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "No re-entrancy.");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owners[msg.sender] = true;
    }

    function verifyOwner() public view returns (bool) {
        return owners[msg.sender];
    }

    function addOwner(address _owner) public hasAuthority {
        require(owners[_owner] == false, "This address already belongs to an owner.");
        owners[_owner] = true;
    }

    function removeOwner(address _owner) public hasAuthority {
        require(owners[_owner] == true, "There is no owner with this address.");
        owners[_owner] = false;
    }

    function claimManagementPool() public hasAuthority nonReentrant {
        require(managementPool > 0, "There are no funds in the pool");
        payable(msg.sender).transfer(managementPool);
        managementPool = 0;
    }

    function addToManagementPool(uint amount) internal {
        managementPool += amount;
    }

    receive() external payable {
        addToManagementPool(msg.value);
    }
}
