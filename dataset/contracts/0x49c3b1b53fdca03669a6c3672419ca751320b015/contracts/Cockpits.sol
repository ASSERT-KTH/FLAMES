// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {UpdatableOperatorFilterer} from "./UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./RevokableDefaultOperatorFilterer.sol";

contract Cockpits is ERC721A, Ownable, RevokableDefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public maxSupply = 999;
    uint256 public mintPrice = .004 ether;
    uint256 public maxPerWallet = 5;
    bool public paused = true;
    string public baseURI = "ipfs://QmYXR9HoskPgBBPtr6reWP7nLX9p2t8HPfdGU2Dh4WxMda/";

    constructor() ERC721A("Cockpits", "Cockpit") {}

    function mint(uint256 amount)
        external
        payable
        mintStatus
        mintCompliance(amount)
        mintPriceCompliance(amount)
    {
        _safeMint(msg.sender, amount);
    }

    function teamMint(address receiver, uint256 mintAmount)
        external
        onlyOwner
    {
        _safeMint(receiver, mintAmount);
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

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        paused = !paused;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setValues(uint256 _newAmount) external onlyOwner {
        maxSupply = _newAmount;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    modifier mintStatus() {
        require(!paused, "Mint paused");
        _;
    }

    modifier mintCompliance(uint256 amount) {
        require((totalSupply() + amount) <= maxSupply, "Max supply reached");
        require(amount <= maxPerWallet, "Max per transaction reached");
        _;
    }

    modifier mintPriceCompliance(uint256 amount) {
        require(msg.value >= (mintPrice * amount), "Wrong mint price");
        _;
    }
}
