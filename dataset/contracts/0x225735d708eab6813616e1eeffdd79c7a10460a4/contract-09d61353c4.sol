// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.9.3/token/ERC20/ERC20.sol";

contract RED is ERC20 {
    constructor() ERC20("RED", "RED") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
