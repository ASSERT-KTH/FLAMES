// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.3/token/ERC20/ERC20.sol";

contract DatBoi is ERC20 {
    constructor() ERC20("DatBoi", "BOI") {
        _mint(msg.sender, 420420420420420 * 10 ** decimals());
    }
}
