//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./BaseErc20.sol";

abstract contract Burnable is BaseErc20, IBurnable {
    
    mapping (address => bool) public ableToBurn;

    modifier onlyBurner() {
        require(ableToBurn[msg.sender], "no burn permissions");
        _;
    }

    // Overrides
    
    function configure(address _owner) internal virtual override {
        ableToBurn[_owner] = true;
        super.configure(_owner);
    }
    
    
    // Admin methods

    function setAbleToBurn(address who, bool enabled) external onlyOwner {
        ableToBurn[who] = enabled;
        emit ConfigurationChanged(msg.sender, "Burner List Changed");
    }


    // Private methods

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function burn(address account, uint256 value) external override onlyBurner {
        require(account != address(0), "Cannot burn from the 0 address");
        if (account != msg.sender) {
            _allowed[account][msg.sender] = _allowed[account][msg.sender] - value;
        }
        
        _totalSupply = _totalSupply - value;
        _balances[account] = _balances[account] - value;
        emit Transfer(account, address(0), value);
    }
}