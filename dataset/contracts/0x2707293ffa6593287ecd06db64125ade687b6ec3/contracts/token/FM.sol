// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./extensions/ERC1363.sol";

contract FM is
    ERC20("FeelingMeta", "FM"),
    ERC20Permit("FeelingMeta"),
    ERC20Burnable,
    ERC1363
{
    constructor() {
        _mint(msg.sender, 1_500_000_000 ether);
    }
}