// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Oordinal abstracts 
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract OORDIN is ERC721Community {
    constructor() ERC721Community("Oordinal abstracts ", "OORDIN", 2000, 1, START_FROM_ONE, "ipfs://bafybeiby6s7phb2da6bbuubzyszkbrycneopwf5227dbmviylekhvmbaf4/",
                                  MintConfig(0.004 ether, 20, 20, 0, 0xEedEC90b72E259c6dEDC8A37Fe4e73B85571f7F7, false, false, false)) {}
}
