// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMintable {
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount
  ) external;

  function mintBatch(
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) external;
}
