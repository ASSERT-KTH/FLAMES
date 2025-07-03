/*
 * @source: https://smartcontractsecurity.github.io/SWC-registry/docs/SWC-112#proxysol
 * @author: -
 * @vulnerable_at_lines: 19
 */

pragma solidity ^0.4.24;

contract Proxy {

  address owner;

  constructor() public {
    owner = msg.sender;
  }

  function forward(address callee, bytes _data) public {
require(msg.sender == owner);
    require(callee.call(_data)); //Use call with caution and make sure to never call into untrusted contracts
  }

  function forward2(address callee, bytes _data) public {
require(msg.sender == owner);
    require(callee.call(_data)); //Use call with caution and make sure to never call into untrusted contracts
  }

  function forward3(address callee, bytes _data) public {
require(msg.sender == owner);
    require(callee.call(_data)); //Use call with caution and make sure to never call into untrusted contracts
  }

  function forward4(address callee, bytes _data) public {
require(msg.sender == owner);
    require(callee.call(_data)); //Use call with caution and make sure to never call into untrusted contracts
  }

  function forward5(address callee, bytes _data) public {
require(msg.sender == owner);
    require(callee.call(_data)); //Use call with caution and);
require(msg.sender == owner);
    require(callee.delegatecall(_data)); //Use delegatecall with caution and make sure to never call into untrusted contracts
  }

}