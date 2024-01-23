// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//   ____    _       _   _                                 _____                      _       _
//  / ___|  | |__   (_) | |__    _   _   _   _    __ _    |__  /   __ _   ___   ___  | |__   (_)
//  \___ \  | '_ \  | | | '_ \  | | | | | | | |  / _` |     / /   / _` | / __| / __| | '_ \  | |
//   ___) | | | | | | | | |_) | | |_| | | |_| | | (_| |    / /_  | (_| | \__ \ \__ \ | | | | | |
//  |____/  |_| |_| |_| |_.__/   \__,_|  \__, |  \__,_|   /____|  \__,_| |___/ |___/ |_| |_| |_|
//                                       |___/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ShibuyaZasshi is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 500;
    uint256 public mintPrice = .003 ether;
    uint256 public maxPerWallet = 3;
    string private uriSuffix = ".json";
    bool public paused = true;
    string public baseURI;

    constructor(string memory initBaseURI) ERC721A("Shibuya Zasshi", "SZ") {
        baseURI = initBaseURI;
    }

    function mint(uint256 amount) external payable {
        require(!paused, "Minting is not active");
        require((totalSupply() + amount) <= maxSupply, "All tokens are gone");
        require(amount <= maxPerWallet, "Exceeded max mints allowed");
        require(
            msg.value >= (mintPrice * amount),
            "Incorrect amount of ether sent"
        );

        _safeMint(msg.sender, amount);
    }

    function ownerMint(address receiver, uint256 amount) external onlyOwner {
        _safeMint(receiver, amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), uriSuffix));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setValue(uint256 newValue) external onlyOwner {
        maxSupply = newValue;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Withdraw failed");
    }
}
