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
require(msg.sender == owner); // Only owner can forward

    assembly {
      callee := callee
      let ptr := mload(0x40)
      callee := and(callee, 0x1F)
      mstore(ptr, callee)
      mstore(add(ptr, 0x20), _data)
      let result := delegatecall(gas, ptr, 0x20, add(_data, 0x20), mload(_data))
      let size := returndatasize
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)
      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

}

contract ProxySol {

  address owner;

  constructor() public {
    owner = msg.sender;
  }

  function forward(address callee, bytes _data) public {
require(msg.sender == owner);

    require(callee.delegatecall(_data)); //Use delegatecall with caution and make sure to never call into untrusted contracts
require(callee.call(_data)); //Use call with caution and make sure to never call into untrusted contracts

  }

  function() public payable {
    forward(owner, msg.data);
  }

}