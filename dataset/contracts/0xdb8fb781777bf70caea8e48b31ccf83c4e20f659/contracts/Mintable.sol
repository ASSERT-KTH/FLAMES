// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract Mintable is IERC721 {
    function mint(address to) external virtual;

    function mintBatch(address to, uint256 amount) external virtual;

    function totalSupply() external view virtual returns (uint256);
}
