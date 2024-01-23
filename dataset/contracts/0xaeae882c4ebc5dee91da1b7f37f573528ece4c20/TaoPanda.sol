// SPDX-License-Identifier: UNLICENSED

/*

We asked TAO's BitAPAI Chat Bot for help and it provided me this code.

https://twitter.com/taopanda_erc20/status/1726035106626679177
https://t.me/tpandacoin

*/

pragma solidity 0.8.20;

import "../ERC20.sol";

contract TaoPanda is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 1e24; // 1 million tokens with 18 decimals
    uint256 public marketingAllocation = INITIAL_SUPPLY / 20; // 5% for marketing
    address public deployer;

    constructor() ERC20("TaoPanda", "TPANDA") {
        deployer = msg.sender;
        _mint(msg.sender, INITIAL_SUPPLY - marketingAllocation);
        _mint(deployer, marketingAllocation);
    }
}