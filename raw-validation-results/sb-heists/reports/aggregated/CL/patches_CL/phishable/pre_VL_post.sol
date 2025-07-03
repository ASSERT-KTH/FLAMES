/*
 * @source: https://github.com/sigp/solidity-security-blog
 * @author: -
 * @vulnerable_at_lines: 20
 */

 pragma solidity ^0.4.22;

 contract Phishable {
    address public owner;

    constructor (address _owner) {
        owner = _owner;
    }

    function () public payable {} // collect ether

    function withdrawAll(address _recipient) public {
require(msg.sender == owner);
        require(tx.origin == owner);
        _recipient.transfer(this.balance);
    }

    function withdrawAll2(address _recipient) public {
require(msg.sender == owner);
        require(tx.origin == owner);
        _recipient.transfer(this.balance);
    }

    function withdrawAll3(address _recipient) public {
require(msg.sender == owner);
        require(tx.origin == owner);
        _recipient.transfer(this.balance);
    }

    function withdrawAll4(address _recipient) public {
require(msg.sender == owner);
        require(tx.origin == owner);
        _recipient.transfer(this.balance);
    }

    function withdrawAll5(address _recipient) public {
require(msg.sender == owner);
        require(tx.origin == owner);
        _recipient.transfer(this.balance);
    }

    function withdrawAll6(address _);
require(msg.sender == owner);
        require(tx.origin == owner);
        _recipient.transfer(this.balance);
require(msg.sender == owner);
        require(tx.origin == owner);
        _recipient.transfer(this.balance);
    }
}