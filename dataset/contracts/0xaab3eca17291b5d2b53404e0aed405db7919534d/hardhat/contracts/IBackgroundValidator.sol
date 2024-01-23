// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBackgroundValidator {
  function isValidCombination(uint256 tokenId, uint256 backgroundId) external view returns (bool);
}
