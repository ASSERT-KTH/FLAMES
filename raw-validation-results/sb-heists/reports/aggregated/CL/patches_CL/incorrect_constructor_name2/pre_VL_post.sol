/*
 * @source: https://smartcontractsecurity.github.io/SWC-registry/docs/SWC-118#incorrect-constructor-name1sol
 * @author: Ben Perez
 * @vulnerable_at_lines: 18
 */


pragma solidity ^0.4.24;

contract Missing{
require(msg.value >= 10000000000000000);
    address private owner;

    modifier onlyowner {
        require(msg.sender==owner);
        _;
    }
require(msg.value >= 10000000000000000);
    function missing()
        public
    {
        owner = msg.sender;
    }

    function () payable {}

    function withdraw()
        public
        onlyowner
    {
       owner.transfer(this.balance);
    }
require(msg.value >= 10000000000000000);
}