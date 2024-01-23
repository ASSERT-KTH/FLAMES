// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ctlc ctlv
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     █████  ██████  ██      █████    //
//    ██        ██    ██     ██        //
//    ██        ██    ██     ██        //
//    ██        ██    ██     ██        //
//     █████    ██    █████   █████    //
//                                     //
//     █████  ██████  ██     ██  ██    //
//    ██        ██    ██     ██  ██    //
//    ██        ██    ██     ██  ██    //
//    ██        ██    ██     ██  ██    //
//     █████    ██    █████    ██      //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract ctlcctlv is ERC1155Creator {
    constructor() ERC1155Creator("ctlc ctlv", "ctlcctlv") {}
}
