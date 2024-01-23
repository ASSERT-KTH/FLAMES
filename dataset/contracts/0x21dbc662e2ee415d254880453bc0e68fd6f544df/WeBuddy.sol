// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: We Buddy
// contract by: buildship.xyz

import "./ERC721Community.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    ##      ## ########    ########  ##     ## ########  ########  ##    ##     //
//    ##  ##  ## ##          ##     ## ##     ## ##     ## ##     ##  ##  ##      //
//    ##  ##  ## ##          ##     ## ##     ## ##     ## ##     ##   ####       //
//    ##  ##  ## ######      ########  ##     ## ##     ## ##     ##    ##        //
//    ##  ##  ## ##          ##     ## ##     ## ##     ## ##     ##    ##        //
//    ##  ##  ## ##          ##     ## ##     ## ##     ## ##     ##    ##        //
//     ###  ###  ########    ########   #######  ########  ########     ##        //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////

contract WeBuddy is ERC721Community {
    constructor() ERC721Community("We Buddy", "WB", 3200, 50, START_FROM_ONE, "ipfs://bafybeickmqcc3shkmxqobyxrgxvfnq7le52xlmfcczemmedpfyt5ggnale/",
                                  MintConfig(0.011 ether, 3, 3, 0, 0x6d43AF71DF7c8362ac4B96920D0C8354130f7569, false, false, false)) {}
}
