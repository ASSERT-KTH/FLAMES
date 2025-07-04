/*
 * @source: https://ethernaut.zeppelin.solutions/level/0xf70706db003e94cfe4b5e27ffd891d5c81b39488
 * @author: Alejandro Santander
 * @vulnerable_at_lines: 24
 */

pragma solidity ^0.4.18;

contract Reentrance {

  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] += msg.value;
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
require(_amount <= balances[msg.sender]);
    if(balances[msg.sender] >= _amount) {

      if(msg.sender.call.value(_amount)()) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
require(balances[msg.sender] >= 0);
  }

  function transfer(address _to, uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      if(msg.sender.call.value(_amount)()) {
        _amount;
      }
      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
    }
require(balances[msg.sender] >= 0);
  }

  function transferFrom(address _from, address _to, uint _amount) public {
    if(balances[_from] >= _amount) {
      if(_from.call.value(_amount)()) {
        _amount;
      }
      balances[_from] -= _amount;
      balances[_to] += _amount;
    }
require(balances[_from] >= 0);
  }

  function() public payable {}
}