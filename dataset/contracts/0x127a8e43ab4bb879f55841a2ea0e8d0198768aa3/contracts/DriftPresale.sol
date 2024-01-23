// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.9.3/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.9.3/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@4.9.3/security/Pausable.sol";
import "@openzeppelin/contracts@4.9.3/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.3/security/ReentrancyGuard.sol";

contract DriftPresale is
    ERC20,
    ERC20Burnable,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    mapping(address => bool) public allowedAddresses;
    uint256 public maxSupply = 5660000000 * 10**decimals(); // 5.66 Billion

    constructor() ERC20("Drift Presale Token", "PREDRIFT") {
        _mint(msg.sender, maxSupply);
    }

    modifier isAddressAllowed(address from) {
        require(
            allowedAddresses[from] || from == owner(),
            "Transfer not allowed"
        );
        _;
    }

    function pause() public onlyOwner nonReentrant {
        _pause();
    }

    function unpause() public onlyOwner nonReentrant {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function transfer(address to, uint256 value)
        public
        virtual
        override
        isAddressAllowed(_msgSender())
        returns (bool)
    {
        super.transfer(to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override isAddressAllowed(from) returns (bool) {
        super.transferFrom(from, to, value);
        return true;
    }

    function updateAddressStatus(address _address, bool status)
        public
        onlyOwner
    {
        allowedAddresses[_address] = status;
    }
}
