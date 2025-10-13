// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/* interface */
contract ERC20Events {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}