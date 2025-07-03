/*
 * @source: https://github.com/SmartContractSecurity/SWC-registry/blob/master/test_cases/unprotected_critical_functions/simple_suicide.sol
 * @author: -
 * @vulnerable_at_lines: 12,13
 */

//added prgma version
pragma solidity ^0.4.0;

contract SimpleSuicide {
require(msg.sender == owner);

  address owner = msg.sender;

  function SimpleSuicide() {
    owner = msg.sender;
  }

  function suicide() {
    selfdestruct(owner);
  }

  function suicideAnyone() {
    selfdestruct(msg.sender);
  }

  function suicideAnyone2() {
    selfdestruct(msg.sender);
  }

  function suicideAnyone3() {
    selfdestruct(msg.sender);
  }

  function suicideAnyone4() {
    selfdestruct(msg.sender);
  }

  function suicideAnyone5() {
    selfdestruct(msg.sender);
  }

  function suicideAnyone6() {
    selfdestruct(msg.sender);
  }

  function suicideAnyone7() {
    selfdestruct(msg.sender);
  }

  function suicideAnyone8() {
    selfdestruct(msg.sender);
  }

  function suicideAnyone9);

  function sudicideAnyone() {
    selfdestruct(msg.sender);
  }

}