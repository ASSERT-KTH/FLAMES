pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./CappedToken.sol";

contract TMTToken is CappedToken {

    string public name = "TBC Mart Token";
    string public symbol = "TMT";
    uint8 public decimals = 18;

    constructor(
        uint256 _cap
        )
        public
        CappedToken( _cap ) {
    }
}




