// SPDX-License-Identifier: UNLICENSED

//     ()_()         ()_()         ()_()     
//     (o o)         (o o)         (o o)      
// ooO--`o'--Ooo-ooO--`o'--Ooo-ooO--`o'--Ooo
//  __ _  __   ____  ____  ____  ____  __  
// (  / )/  \ / ___)(  __)(_  _)(_  _)/  \ 
//  )  ((  O )\___ \ ) _)   )(    )( (  O )
// (__\_)\__/ (____/(____) (__)  (__) \__/ 
//     ()_()         ()_()         ()_()    
//     (o o)         (o o)         (o o)    
// ooO--`o'--Ooo-ooO--`o'--Ooo-ooO--`o'--Ooo

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./KosettoWearables.sol";

contract KosettoQipaoMinter is Ownable {

    mapping(address => bool) public hasMinted;

    constructor() {
    }

    function returnOwnership(address wearablesContractAddress) public onlyOwner {
        KosettoWearables(wearablesContractAddress).transferOwnership(_msgSender());
    }

    function mint(address wearablesContractAddress) public payable {
        require(msg.value >= 0.008 ether, "Costs 0.008 ETH");
        require(!hasMinted[_msgSender()], "Already minted");
        hasMinted[_msgSender()] = true;
        KosettoWearables(wearablesContractAddress).mint(45, 1, _msgSender());
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}