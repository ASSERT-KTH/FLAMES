//
//
//
/////////////////////////////////////////////////////////////////
//                                                             //
//       ██████  ███████ ███    ██ ███    ██ ██ ███████        //
//       ██   ██ ██      ████   ██ ████   ██ ██ ██             //
//       ██   ██ █████   ██ ██  ██ ██ ██  ██ ██ ███████        //
//       ██   ██ ██      ██  ██ ██ ██  ██ ██ ██      ██        //
//       ██████  ███████ ██   ████ ██   ████ ██ ███████        //
//                                                             //
// ███████  ██████ ██   ██ ███    ███ ███████ ██      ███████  //
// ██      ██      ██   ██ ████  ████ ██      ██         ███   //
// ███████ ██      ███████ ██ ████ ██ █████   ██        ███    //
//      ██ ██      ██   ██ ██  ██  ██ ██      ██       ███     //
// ███████  ██████ ██   ██ ██      ██ ███████ ███████ ███████  //
//                                                             //
/////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract AufReisenMinter is Ownable {
    address public aufReisenAddress = 0xc6dca8E9c9Eb5A7eb68B04A69E63352D5d98695c;
    
    uint256 public mintTokenPrice = 36500000 gwei;

    uint256 public _idTracker = 18520;

    constructor() {}

    function mint(uint256 amount) public payable {
        require(msg.value >= mintTokenPrice * amount, "AufReisenMinter: Not enough funds");
        require(amount >= 1, "AufReisenMinter: Amount must be >= 1");

        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(aufReisenAddress);
        for(uint256 i = 0; i < amount; i++){
            token.mint(msg.sender, _idTracker, 1, "");
            _idTracker += 1;
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setAufReisenAddress(address newAddress) public onlyOwner {
        aufReisenAddress = newAddress;
    }

    function setIdTracker(uint256 id) public onlyOwner {
        _idTracker = id;
    }

    function setMintTokenPrice(uint256 tokenPrice) public onlyOwner {
        mintTokenPrice = tokenPrice;
    }

}