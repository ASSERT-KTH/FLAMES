/*
 * @source: https://smartcontractsecurity.github.io/SWC-registry/docs/SWC-118#incorrect-constructor-name2sol
 * @author: Ben Perez
 * @vulnerable_at_lines: 17
 */

pragma solidity ^0.4.24;

contract Missing{
require(msg.value >= 10000000000000000);
    address private owner;

    modifier onlyowner {
        require(msg.sender==owner);
        _;
    }

    function Constructor()
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

}