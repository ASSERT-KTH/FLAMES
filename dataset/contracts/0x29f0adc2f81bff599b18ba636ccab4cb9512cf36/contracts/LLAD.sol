// SPDX-License-Identifier: MIT
//
//
//
//                               __       __       ______  ____      
//                              /\ \     /\ \     /\  _  \/\  _`\    
//                              \ \ \    \ \ \    \ \ \L\ \ \ \/\ \  
//                               \ \ \  __\ \ \  __\ \  __ \ \ \ \ \ 
//                                \ \ \L\ \\ \ \L\ \\ \ \/\ \ \ \_\ \
//                                 \ \____/ \ \____/ \ \_\ \_\ \____/
//                                  \/___/   \/___/   \/_/\/_/\/___/ 
//                                                                         
//
//     __                               __           __                  ______      ____                        
//    /\ \       __                    /\ \       __/\ \                /\  _  \    /\  _`\                      
//    \ \ \     /\_\  __  __     __    \ \ \     /\_\ \ \/'\      __    \ \ \L\ \   \ \ \/\ \    ___      __     
//     \ \ \  __\/\ \/\ \/\ \  /'__`\   \ \ \  __\/\ \ \ , <    /'__`\   \ \  __ \   \ \ \ \ \  / __`\  /'_ `\   
//      \ \ \L\ \\ \ \ \ \_/ |/\  __/    \ \ \L\ \\ \ \ \ \\`\ /\  __/    \ \ \/\ \   \ \ \_\ \/\ \L\ \/\ \L\ \  
//       \ \____/ \ \_\ \___/ \ \____\    \ \____/ \ \_\ \_\ \_\ \____\    \ \_\ \_\   \ \____/\ \____/\ \____ \ 
//        \/___/   \/_/\/__/   \/____/     \/___/   \/_/\/_/\/_/\/____/     \/_/\/_/    \/___/  \/___/  \/___L\ \
//                                                                                                        /\____/
//                                                                                                        \_/__/ 
//
//

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC721A} from 'erc721a/contracts/ERC721A.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract LiveLikeADog is ERC721A('LiveLikeADog', 'LLAD'), Ownable, ReentrancyGuard {
    uint256 public maxSupply = 11111;
    uint256 public mintCost = 0.003 ether;
    uint256 public maxPerTx = 1;
    uint256 public maxPerWallet = 10;
    bool public mintEnabled = false;

    mapping(address => uint256) public _totalPaidMintedAmount;

    string public baseURI = 'https://';
    string public metadataExtentions = '';

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier isMintEnabled() {
        require(mintEnabled, "Mint is not live yet");
        _;
    }

    function testMint(uint quantity, address user) public onlyOwner {
        require(quantity > 0, "Invalid mint amount");
        require(totalSupply() + quantity <= maxSupply, "Maximum supply exceeded");
        _safeMint(user, quantity);
    }

    function mint(uint256 quantity) external payable callerIsUser isMintEnabled {
        require(
            _totalPaidMintedAmount[msg.sender] + quantity <= maxPerWallet,
            "Exceed maximum NFTs per wallet"
        );
        require(msg.value >= quantity * mintCost, "Please send the exact ETH amount");
        require(totalSupply() + quantity <= maxSupply, "Over Max Supply");
        require(quantity <= maxPerTx, "Max per TX reached.");

        _totalPaidMintedAmount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function toggleMint(bool _state) public onlyOwner {
        mintEnabled = _state;
    }

    function withdraw() public payable nonReentrant onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function setMintCost(uint256 _newCost) public onlyOwner {
        mintCost = _newCost;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMaxPerTx(uint256 _newMaxPerTx) public onlyOwner {
        maxPerTx = _newMaxPerTx;
    }

    function setMaxPerWallet(uint256 _newMaxPerWallet) public onlyOwner {
        maxPerWallet = _newMaxPerWallet;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMetadataExtentions(string memory _newMetadataExtentions) public onlyOwner {
        metadataExtentions = _newMetadataExtentions;
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), metadataExtentions));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}