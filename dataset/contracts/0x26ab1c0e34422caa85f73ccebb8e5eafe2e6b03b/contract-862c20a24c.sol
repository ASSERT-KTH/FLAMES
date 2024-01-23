// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.9.3/token/ERC20/ERC20.sol";

contract BLUE is ERC20 {
    constructor() ERC20("BLUE", "BLUE") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
