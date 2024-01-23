// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

contract WiggleEthscriborESIP3 {
    error MintNotOpened();
    error MintClosed();
    error NotEnoughEther();
    error NotDeployer();

    address public deployer = msg.sender;

    uint public mintPrice = 0.001 ether;
    uint public mintOpenBlock = 18144000;
    uint public mintCloseBlock = 99999999;

    event ethscriptions_protocol_CreateEthscription(
        address indexed initialOwner,
        string contentURI
    );

    function ethscribe(string memory dataURI) public payable {
        if (block.number < mintOpenBlock) {
            revert MintNotOpened();
        }
        if (block.number > mintCloseBlock) {
            revert MintClosed();
        }
        if (msg.sender != address(deployer) && msg.value < mintPrice) {
            revert NotEnoughEther();
        }

        emit ethscriptions_protocol_CreateEthscription(msg.sender, string(abi.encodePacked(dataURI)));
    }

    function settings(uint _mintPrice, uint _mintOpenBlock, uint _mintCloseBlock) public {
        if (msg.sender != deployer) {
            revert NotDeployer();
        }
        
        mintPrice = _mintPrice;
        mintOpenBlock = _mintOpenBlock;
        mintCloseBlock = _mintCloseBlock;
    }

    function withdraw(uint amount, address to) public {
        if (msg.sender != deployer) {
            revert NotDeployer();
        }

        payable(to).transfer(amount == 0 ? address(this).balance : amount);
    }
}


