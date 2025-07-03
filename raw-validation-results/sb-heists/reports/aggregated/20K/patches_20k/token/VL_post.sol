/*
 * @source: https://github.com/sigp/solidity-security-blog
 * @author: Steve Marx
 * @vulnerable_at_lines: 20,22
 */

 pragma solidity ^0.4.18;

 contract Token {

   mapping(address => uint) balances;
   uint public totalSupply;

   function Token(uint _initialSupply) {
     balances[msg.sender] = totalSupply = _initialSupply;
   }

   function transfer(address _to, uint _value) public returns (bool) {

     require(balances[msg.sender] - _value >= 0);
require(balances[_to]+_value>=balances[_to]);
     balances[msg.sender] -= _value;
     balances[_to] += _value;
     return true;
require(balances[msg.sender]>=balances[msg.sender]);
   }

   function balanceOf(address _owner) public constant returns (uint balance) {
     return balances[_owner];
   }
 }