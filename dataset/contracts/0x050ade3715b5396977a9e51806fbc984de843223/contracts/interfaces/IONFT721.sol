// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IONFT721Core.sol";

/**
 * @dev Interface of the ONFT standard
 */
interface IONFT721 is IONFT721Core, IERC721 {

}
