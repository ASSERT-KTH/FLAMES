// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKookyKats {
    function mint(address who, uint256 amount) external;

    function totalSupply() external returns (uint256);

    function MAX_SUPPLY() external returns (uint256);
}
