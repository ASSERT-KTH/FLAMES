// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZeroPointEnergy
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ccccccccc:::::::cccccccc::::::::ccccccccccccccccc::::::::cccccccc::::::::ccccccc    //
//    llllllllcccccc::::::c::::::cccccclllllllllllllllcccccc::::::c::::::cccccclllllll    //
//    oooooooolllllcccc::::::cccclllllooooooooooooooooolllllccc:::::::cccclllllooooooo    //
//    ooooooooooooolllcccc:cccllloooooooooooooooooooooooooollllccc::cccllloooooooooooo    //
//    cccccllllooooooolllccllloooooooolllcccccccccccllloooooooollccclllooooooollllcccc    //
//    ::::::::cccloooooolllloooooollcc:::::::::::::::::cclloooooolllloooooolccc:::::::    //
//    ::::::::::::ccloooooooooollcc:::::::::::::::::::::::cclloooooooooollc:::::::::::    //
//    ::::::::::::::cclooodooolc:::::::::::::::::::::::::::::clloooooolcc:::::::::::::    //
//    ccccc:::::::::::cloooolc:::::::::::ccccccccccc:::::::::::cloooocc:::::::::::cccc    //
//    ccccccccc:::::::::clolc:::::::::ccccccccccccccccc:::::::::clolc:::::::::cccccccc    //
//    ccccccccccc::::::::ccc::::::::ccccccccccccccccccccc::::::::ccc::::::::cccccccccc    //
//    llllcccccccc::::::::::::::::cccccccclllllllllcccccccc::::::::::::::::cccccccclll    //
//    lllllllcccccc::::::::::::::cccccccllllllllllllllcccccc::::::::::::::ccccccllllll    //
//    lllllllccccccc:::::::::::::cccccllllllllllllllllcccccc:::::::::::::cccccclllllll    //
//    llllllllcccccc:::::::::::::ccccclllllllllllllllllccccc:::::::::::::cccccclllllll    //
//    llllllllcccccc:::::::::::::ccccclllllllllllllllllccccc:::::::::::::cccccclllllll    //
//    llllllllccccc::::::::::::::cccccclllllllllllllllcccccc::::::::::::::ccccclllllll    //
//    lllllcccccccc:::::::::::::::cccccclllllllllllllcccccc:::::::::::::::ccccccclllll    //
//    lllccccccccc:::::::cc::::::::cccccccclllllcccccccccc::::::::cc:::::::cccccccccll    //
//    cccccccccc::::::::cllc::::::::ccccccccccccccccccccc::::::::clc:::::::::ccccccccc    //
//    cccccccc:::::::::cloolc::::::::::ccccccccccccccc::::::::::cloolc:::::::::ccccccc    //
//    ccc::::::::::::ccloooolcc:::::::::::::ccccc:::::::::::::clooooolcc::::::::::::cc    //
//    :::::::::::::ccloooooooolcc:::::::::::::::::::::::::::ccloooooooolc:::::::::::::    //
//    ::::::::::ccclooooollooooollcc:::::::::::::::::::::ccllooooollooooolccc:::::::::    //
//    ::::::ccclloooooolllllloooooollcccc:::::::::::cccclloooooolllllloooooollccc:::::    //
//    llllllloooooooolllcccclllooooooooollllllllllllloooooooollllcccclllooooooooolllll    //
//    ooooooooooollllccc::::cccllllooooooooooooooooooooooollllccc:::cccclllloooooooooo    //
//    ooooollllllccccc:::::::::ccccllllllooooooooooollllllcccc:::::::::ccccclllllloooo    //
//    lllccccccccc::::::cccc::::::ccccccccclllllllcccccccc:::::::cccc::::::cccccccclll    //
//    cccccccc::::::::cccccccc:::::::::ccccccccccccccc:::::::::cccccccc:::::::::cccccc    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract ZPE is ERC721Creator {
    constructor() ERC721Creator("ZeroPointEnergy", "ZPE") {}
}
