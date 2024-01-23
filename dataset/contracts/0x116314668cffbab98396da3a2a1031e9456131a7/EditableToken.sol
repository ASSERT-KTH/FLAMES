
pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./BasicERC20.sol";
import "./Ownable.sol";

contract EditableToken is BasicERC20, Ownable {
    using SafeMath for uint256;

    // change owner to 0x0 to lock this function
    function editTokenProperties(string _name, string _symbol, int256 extraSupplay) onlyOwner public {
        name = _name;
        symbol = _symbol;
        if (extraSupplay > 0)
        {
            balanceOf[owner] = balanceOf[owner].add(uint256(extraSupplay));
            totalSupply = totalSupply.add(uint256(extraSupplay));
            emit Transfer(address(0x0), owner, uint256(extraSupplay));
        }
        else if (extraSupplay < 0)
        {
            balanceOf[owner] = balanceOf[owner].sub(uint256(extraSupplay * -1));
            totalSupply = totalSupply.sub(uint256(extraSupplay * -1));
            emit Transfer(owner, address(0x0), uint256(extraSupplay * -1));
        }
    }
}