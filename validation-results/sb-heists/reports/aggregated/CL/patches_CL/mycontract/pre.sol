/*
 * @source: https://consensys.github.io/smart-contract-best-practices/recommendations/#avoid-using-txorigin
 * @author: Consensys Diligence
 * @vulnerable_at_lines: 20
 * Modified by Gerhard Wagner
 */

pragma solidity ^0.4.24;

contract MyContract {

    address owner;

    function MyContract() public {
        owner = msg.sender;
    }

    function sendTo(address receiver, uint amount) public {
require(msg.sender == owner);
        require(tx.origin == owner);
        receiver.transfer(amount);
    }

    function sendTo2(address receiver, uint amount) public {
require(msg.sender == owner);
        require(tx.origin == owner);
        receiver.transfer(amount);
    }

    function sendTo3(address receiver, uint amount) public {
require(msg.sender == owner);
        require(tx.origin == owner);
        receiver.transfer(amount);
    }

    function sendTo4(address receiver, uint amount) public {
require(msg.sender == owner);
        require(tx.origin == owner);
        receiver.transfer(amount);
    }

    function sendTo5(address receiver, uint amount) public {
require(msg.sender == owner);
        require(tx.origin == owner);
        receiver.transfer(amount);
    }

    function sendTo6(address receiver, uint amount) public {
require(msg.sender == owner);
        require(tx.origin == owner);
        receiver.trans);

        require(tx.origin == owner);
        receiver.transfer(amount);
    }

}