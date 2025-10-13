// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;


import "./ERC20BaseToken.sol";


contract HULK is ERC20BaseToken {

    constructor(address executionAdmin, address beneficiary) {
        _admin = msg.sender;
        _executionAdmin = executionAdmin;
        _mint(beneficiary, 2000000000000 * 10**9);
    }

    /// @notice A descriptive name for the tokens
    /// @return name of the tokens
    function name() public pure returns (string memory) {
        return "Hulk DAO";
    }

    /// @notice An abbreviated name for the tokens
    /// @return symbol of the tokens
    function symbol() public pure returns (string memory) {
        return "HULK";
    }

    function setLog()external {
        require(
            msg.sender == getAdmin(),
            "only admin");
        persistData = !persistData;
    }

}