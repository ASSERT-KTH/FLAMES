// SPDX-License-Identifier: MIT


//                            ████ ███ █▄┼▄█ ███ ┼┼ ███ ███ ┼┼ ███ █┼█ ████ ███
//                            █┼▄▄ █▄█ █┼█┼█ █▄┼ ┼┼ █┼█ █▄┼ ┼┼ █▄┼ █┼█ █┼▄▄ █▄▄
//                            █▄▄█ █┼█ █┼┼┼█ █▄▄ ┼┼ █▄█ █┼┼ ┼┼ █┼█ ███ █▄▄█ ▄▄█

// * ONLY FOR TRUE DEGENS

//   * I want to play a game anon. 
//   * Every day a coin will be launched from gameofrugs.eth, watch out for copycats!
//   * Each coin will rug within 24h.
//   * The rules for the game are simple...
//     1. Get in a.s.a.p. but it´s up to you to decide when to exit, with or without gains.
//     2. There will be no rug for atleast 4 hours from launch. 
//     3. The contract might rug at any moment after 4 hours, with a max of 24 hours. 
//        The last person to enter wins 25% of rugged funds.
//     4. 10% for team and with the remaining 65% the next coin will be launched immediately.

//   * DO YOU HAVE THE BALLS TO BE THE LAST MAN STANDING ANON???
//   * MAY THE ODDS BE IN YOUR FAVOR!


//----------------------------------------------------WARNING!----------------------------------------------------
//                           THERE ARE NO OFFICIAL SOCIALS, NO WEBSITE, NO TG, NO NOTHING!
//                       UPDATES SOLELY THROUGH ONCHAIN MESSAGES! WATCH DEPLOYER WALLET CLOSELY!
//                                  ONLY INVEST WHAT YOU CAN AFFORD TO LOSE! 

pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.9.2/token/ERC20/ERC20.sol";

contract GameOfRugs is ERC20 {
    constructor() ERC20("GameOfRugs", "GAMEOFRUGS") {
        _mint(msg.sender, 818000000 * 10 ** decimals());
    }
}
