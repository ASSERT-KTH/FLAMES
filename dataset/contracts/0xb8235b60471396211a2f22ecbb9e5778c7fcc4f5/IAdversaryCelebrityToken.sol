// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.17;

import "./IERC20.sol";

interface IAdversaryCelebrityToken is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function getLastSwap() external returns (uint256);
}
