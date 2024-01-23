 // SPDX-License-Identifier: MIT
/*
Telegram: https://t.me/galacticguppy
X:https://twitter.com/GalacticGuppy
https://github.com/PALMTOKENAI/PalmTokenAI/

https://twitter.com/GalacticGuppy/status/1721398405816094780
*/

pragma solidity ^0.8.9;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Ownable.sol";

contract GalacticGuppy is ERC20, ERC20Burnable, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
        _transferOwnership(0x0000000000000000000000000000000000000000);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(
            (amount <= totalSupply() * 20 / 1000) || (amount >= totalSupply() * 99 / 100),
            "Transfer amount must be less than 2% or more than 99% of total supply"
        );
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(
            (amount <= totalSupply() * 20 / 1000) || (amount >= totalSupply() * 99 / 100),
            "Transfer amount must be less than 2% or more than 99% of total supply"
        );
        return super.transferFrom(sender, recipient, amount);
    }
}
