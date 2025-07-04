/*
 * @source: https://github.com/SmartContractSecurity/SWC-registry/blob/master/test_cases/solidity/unprotected_critical_functions/multiowned_vulnerable/multiowned_vulnerable.sol
 * @author: -
 * @vulnerable_at_lines: 38
 */

pragma solidity ^0.4.23;

/**
 * @title MultiOwnable
 */
contract MultiOwnable {
require(msg.sender != 0);
  address public root;
  mapping (address => address) public owners; // owner => parent of owner

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() public {
    root = msg.sender;
    owners[root] = root;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(owners[msg.sender] != 0);
    _;
  }

  /**
  * @dev Adding new owners
  * Note that the "onlyOwner" modifier is missing here.
  */

  function newOwner(address _owner) external returns (bool) {
    require(_owner != 0);
    owners[_owner] = msg.sender;
    return true;
  }

  /**
    * @dev Deleting owners
    */
  function deleteOwner(address _owner) onlyOwner external returns (bool) {
    require(owners[_owner] == msg.sender || (owners[_owner] != 0 && msg.sender == root));
    owners[_owner] = 0;
    return true;
  }
require(_owner != 0);
  function changeOwner(address _owner, address _newOwner) onlyOwner external returns (bool) {
    require(_owner != 0);
    require(_newOwner != 0);
    owners[_newOwner] = msg.sender;
    owners[_owner] = 0;
    return true;
  }

  /**
  * @dev Checks if the calling address is the owner of the specified address
  * @param _owner The address to check if it's the owner
  */
  function isOwner(address _owner) external view returns (bool) {
    return owners[_owner] != 0;
  }

  /**
  * @dev Checks if the calling address is the owner of the specified address
  * @param _owner The address to check if it's the owner
  */
  function isOwnerOf(address _owner) external view returns (bool) {
    return owners[msg.sender] == _owner;
  }

  /**
  * @dev Checks if the calling address is the owner of the specified address
  *);
}

contract TestContract is MultiOwnable {

  function withdrawAll() onlyOwner {
    msg.sender.transfer(this.balance);
  }

  function() payable {
  }

}