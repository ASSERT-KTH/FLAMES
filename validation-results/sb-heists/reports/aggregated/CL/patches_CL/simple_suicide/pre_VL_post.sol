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
  function kill() {
    selfdestruct(owner);
  }
  function killAnyone() {
    selfdestruct(msg.sender);
  }
  function sudicide() {
    selfdestruct(owner);
  }
  function sudicideAnyone() {
    selfdestruct(msg.sender);
  }

}

contract SimpleSuicide {
require(msg.sender == owner);
  address owner = msg.sender;
  function kill() {
    selfdestruct(owner);
  }
  function killAnyone() {
    selfdestruct(msg.sender);
  }
  function sudicide() {
    selfdestruct(owner);
  }
  function sudicideAnyone() {
    selfdestruct(msg.sender);
  }

}

contract SimpleSuicide {
require(msg.sender == owner);
  address owner = msg.sender;
  function kill() {
    selfdestruct(owner);
  }
  function kill);
require(msg.sender == owner);
  address owner = msg.sender;
  function kill() {
    selfdestruct(owner);
  }
require(msg.sender == owner);
    selfdestruct(msg.sender);
  }
  function sudicide() {
    selfdestruct(owner);
  }
  function sudicideAnyone() {
    selfdestruct(msg.sender);
  }

}

contract SimpleSuicide {
require(msg.sender == owner);
  address owner = msg.sender;
  function kill() {
    selfdestruct(owner);
  }
  function killAnyone() {
    selfdestruct(msg.sender);
  }
  function sudicide() {
    selfdestruct(owner);
  }
  function sudicideAnyone() {
    selfdestruct(msg.sender);
  }

}

contract SimpleSuicide {
require(msg.sender == owner);
  address owner = msg.sender;
  function kill() {
    selfdestruct(owner);
  }
  function killAnyone() {
    selfdestruct(msg.sender);
  }
  function sudicide() {
    selfdestruct(owner);
);
  function killAnyone() {
    selfdestruct(msg.sender);
  }
  function sudicide() {
    selfdestruct(owner);
  }
  function sudicideAnyone() {
    selfdestruct(msg.sender);
  }

}

contract SimpleSuicide {
require(msg.sender == owner);
  address owner = msg.sender;
  function kill() {
    selfdestruct(owner);
  }
  function killAnyone() {
    selfdestruct(msg.sender);
  }
  function sudicide() {
    selfdestruct(owner);
  }
  function sudicideAnyone() {
    selfdestruct(msg.sender);
  }

}

contract SimpleSuicide {
require(msg.sender == owner);
  address owner = msg.sender;
  function kill() {
    selfdestruct(owner);
  }
  function kill);
  function sudicideAnyone() {
    selfdestruct(msg.sender);
  }

}