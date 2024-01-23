// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//  ______       __     __  __     ______
// /\  == \     /\ \   /\ \_\ \   /\  ___\
// \ \  __<    _\_\ \  \ \____ \  \ \ \____
//  \ \_____\ /\_____\  \/\_____\  \ \_____\
//   \/_____/ \/_____/   \/_____/   \/_____/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BoredJimmyYachtClub is ERC721A, Ownable {
    uint256 public maxSupply = 6969;
    uint256 public mintPrice = 0.002 ether;
    uint256 public maxMintPerTx = 20;
    uint256 public maxFreeMintPerWallet = 1;
    bool public paused = true;

    using Strings for uint256;
    string public baseURI = "ipfs://QmatRT5dqyAXHV8YpMM31soS1DguQG8kJ9w3yoNuyNYtGf/";
    mapping(address => uint256) private mintedFreeAmount;
    mapping(address => uint256) private mintedPerWallet;

    constructor() ERC721A("Bored Jimmy Yacht Club", "BJYC") {}

    function mint(uint256 count) external payable {
        require(!paused, "Mint is paused");

        uint256 cost = (msg.value == 0 &&
            (mintedFreeAmount[msg.sender] + count <= maxFreeMintPerWallet))
            ? 0
            : mintPrice;

        require(
            mintedPerWallet[msg.sender] + count <= maxMintPerTx,
            "Max per wallet reached"
        );
        require(msg.value >= count * cost, "Please send the exact amount");
        require(totalSupply() + count <= maxSupply, "Max supply reached");
        require(count <= maxMintPerTx, "Max per tx reached");

        if (cost == 0) {
            mintedFreeAmount[msg.sender] += count;
        } else {
            mintedPerWallet[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
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
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function reserveMint(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxFreeMint(uint256 newMaxFreeMint) external onlyOwner {
        maxFreeMintPerWallet = newMaxFreeMint;
    }

    function cutSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
