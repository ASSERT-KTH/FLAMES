// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.9.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.9.2/access/Ownable.sol";

contract XPEPE is ERC20, Ownable {
    constructor() ERC20("XPEPE", "XPEPE") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }
}
