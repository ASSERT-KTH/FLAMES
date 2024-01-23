// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Symblocks
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract SYM is ERC721Community {
    constructor() ERC721Community("Symblocks", "SYM", 3000, 50, START_FROM_ONE, "ipfs://bafybeiagxalhxup25blmp2wzabkrq27edmky52q4zdbexrlddpuxwrhx54/",
                                  MintConfig(0.0041 ether, 5, 5, 0, 0x6d43AF71DF7c8362ac4B96920D0C8354130f7569, false, false, false)) {}
}
