// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.9.1/token/ERC20/ERC20.sol";

contract KosBlock is ERC20 {
    constructor() ERC20("Kos Block", "KOS") {
        _mint(msg.sender, 777777777 * 10 ** decimals());
    }
}
