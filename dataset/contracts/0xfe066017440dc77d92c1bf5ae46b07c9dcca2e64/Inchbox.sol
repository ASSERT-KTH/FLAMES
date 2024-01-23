// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Inchbox
// contract by: buildship.xyz

import "./ERC721Community.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//      ####    ##  ##    ####    ##  ##   #####     ####    ##  ##      //
//       ##     ### ##   ##  ##   ##  ##   ##  ##   ##  ##   ##  ##      //
//       ##     ######   ##       ##  ##   ##  ##   ##  ##    ####       //
//       ##     ######   ##       ######   #####    ##  ##     ##        //
//       ##     ## ###   ##       ##  ##   ##  ##   ##  ##    ####       //
//       ##     ##  ##   ##  ##   ##  ##   ##  ##   ##  ##   ##  ##      //
//      ####    ##  ##    ####    ##  ##   #####     ####    ##  ##      //
//                                                                      //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

contract Inchbox is ERC721Community {
    constructor() ERC721Community("Inchbox", "ibox", 10000, 100, START_FROM_ONE, "ipfs://bafybeibdf4avzrrbre7okz4ywpdlzxmspr2qqblfzrk32rmvpegceu5eka/",
                                  MintConfig(0.0005 ether, 10, 50, 0, 0x6d43AF71DF7c8362ac4B96920D0C8354130f7569, false, false, false)) {}
}
