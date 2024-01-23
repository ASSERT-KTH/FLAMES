
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Holy Fuck Tree: Sticks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    ______     ______   __     ______     __  __         //
//    /\  ___\   /\__  _\ /\ \   /\  ___\   /\ \/ /        //
//    \ \___  \  \/_/\ \/ \ \ \  \ \ \____  \ \  _"-.      //
//     \/\_____\    \ \_\  \ \_\  \ \_____\  \ \_\ \_\     //
//      \/_____/     \/_/   \/_/   \/_____/   \/_/\/_/     //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract STICK is ERC1155Creator {
    constructor() ERC1155Creator("Holy Fuck Tree: Sticks", "STICK") {}
}
