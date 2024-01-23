// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ERC20Permit } from "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";

abstract contract IERC20Permit is ERC20Permit {
  function mint() external virtual;
}
