// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOAT.sol";

/**
 * @dev OAT interface
 */
interface IOAT is IERC20 {
  /**
   *
   * @dev emitToken
   *
   */
  function emitToken(address receiver_, uint256 amount_) external;

  /**
   *
   * @dev addEmitter
   *
   */
  function addEmitter(address emitter_) external;

  /**
   *
   * @dev removeEmitter
   *
   */
  function removeEmitter(address emitter_) external;

  /**
   *
   * @dev setTreasury
   *
   */
  function setTreasury(address treasury_) external;
}
