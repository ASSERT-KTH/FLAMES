pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**

 */
contract ULMC is ERC20, ERC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("UltraLink Machine System Ecological Rights Token", "ULMC", 18) {
        _mint(msg.sender, 10000000000 * (10 ** uint256(decimals())));
    }
}