// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IBurnable {
  function burn(
    address from,
    uint256 tokenId,
    uint256 amount
  ) external;
}

interface IERC1155Burnable is IERC1155, IBurnable {}
