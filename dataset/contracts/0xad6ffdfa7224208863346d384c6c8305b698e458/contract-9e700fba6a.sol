// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.3/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.8.3/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@4.8.3/access/Ownable.sol";

contract CYANIDE is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("CYANIDE", "CHX") {
        _mint(msg.sender, 21080085069420 * 10 ** decimals());
    }
}
