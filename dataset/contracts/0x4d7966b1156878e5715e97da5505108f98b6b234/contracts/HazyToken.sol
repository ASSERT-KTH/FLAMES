// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HazyToken is ERC20 {
    constructor() ERC20("Hazy Token", "HZY") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}
