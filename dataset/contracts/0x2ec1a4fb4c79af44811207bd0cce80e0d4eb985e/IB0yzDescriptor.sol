// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IB0yzDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed, uint256[] memory hash) external view returns (string memory);
}