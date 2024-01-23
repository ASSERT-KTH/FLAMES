// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IUsdt {
    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}
