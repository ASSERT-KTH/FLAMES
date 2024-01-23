pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./BasicERC20.sol";

contract ThirdPartyTransferableToken is BasicERC20{
    using SafeMath for uint256;

    struct confidenceInfo {
        uint256 nonce;
        mapping (uint256 => bool) operation;
    }
    mapping (address => confidenceInfo) _confidence_transfers;

    function nonceOf(address src) view public returns (uint256) {
        return _confidence_transfers[src].nonce;
    }

    function transferByThirdParty(uint256 nonce, address where, uint256 amount, uint8 v, bytes32 r, bytes32 s) public returns (bool){
        assert(where != address(this));
        assert(where != address(0x0));

        bytes32 hash = sha256(this, nonce, where, amount);
        address src = ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s);
        assert(balanceOf[src] >= amount);
        assert(nonce == _confidence_transfers[src].nonce+1);

        assert(_confidence_transfers[src].operation[uint256(hash)]==false);

        balanceOf[src] = balanceOf[src].sub(amount);
        balanceOf[where] = balanceOf[where].add(amount);
        _confidence_transfers[src].nonce += 1;
        _confidence_transfers[src].operation[uint256(hash)] = true;

        emit Transfer(src, where, amount);

        return true;
    }
}