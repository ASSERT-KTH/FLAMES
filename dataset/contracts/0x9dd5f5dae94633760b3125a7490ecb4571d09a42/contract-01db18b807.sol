// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.0/token/ERC20/extensions/ERC20Burnable.sol";

contract BEEF is ERC20, ERC20Burnable {
    constructor() ERC20("BEEF", "BEEF") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}
