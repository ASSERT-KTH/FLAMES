pragma solidity ^0.4.24;
import "./MintableToken.sol";
import "./BurnableToken.sol";
import "./Ownable.sol";

contract FCChainAsset is Ownable,BurnableToken, MintableToken{
    string public name = "FCChainAssetCoin";
    string public symbol = "FC";
    uint8 public decimals = 6;
    uint256 public INITIAL_SUPPLY = 200000000 * (10 ** uint256(decimals));

    mapping (address => bool) accessAllowed;
    constructor()public{
        totalSupply_ = INITIAL_SUPPLY;
        balances[tx.origin] = INITIAL_SUPPLY;
        accessAllowed[msg.sender] = true;
    }

    function getBalance(address addr)public view returns(uint256) {
        return balances[addr];
    }


    modifier platform() {
        require(accessAllowed[msg.sender] == true);
        _;
    }

    function allowAccess(address _addr) onlyOwner public {
        accessAllowed[_addr] = true;
    }

    function denyAccess(address _addr) onlyOwner public {
        accessAllowed[_addr] = false;
    }
}
