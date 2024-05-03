// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EnglishAuction {

    function start() external {
        require(msg.value==(_tokens[0].isETH()?maxAmounts[0]:(_tokens[1].isETH()?maxAmounts[1]:0)));
        require(msg.sender == seller, "not seller");


    }

}
