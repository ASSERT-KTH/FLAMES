// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

/*
    IF YOU KNOW -- YOU KNOW
*/

contract Mitochondrion is ERC20 {
    constructor() ERC20("Mitochondrion", "Mitochondrion") {
        _mint(msg.sender, 451_451_451_451 * 10 ** 18);
    }
} 