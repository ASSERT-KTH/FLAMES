// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Ememoji is ERC721A, Ownable, DefaultOperatorFilterer {
    bool public isSale = false;
    uint256 public constant max_supply = 1069;
    uint256 public price = 0.0096 ether;
    uint256 public per_wallet = 5;
    string private baseURI = "null";

    constructor(string memory _baseUri) ERC721A("Ememoji", "MEME") {
        baseURI = _baseUri;
    }

    function mint(uint256 quantity) external payable {
        require(isSale, "Sale not active");
        require(msg.sender == tx.origin, "No contracts allowed");
        require(balanceOf(msg.sender) + quantity <= per_wallet, "Exceeds max per wallet");
        require(totalSupply() + quantity <= max_supply, "Max supply exceeded");
        require(price * quantity <= msg.value, "Not enough funds");
        _mint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity, address to) external onlyOwner {
        require(totalSupply() + quantity < max_supply,"Exceeds max supply");
        _mint(to, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function changePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function changePerWallet(uint256 _per) external onlyOwner {
        per_wallet = _per;
    }

    function changeBaseURI(string memory _baseUri) external onlyOwner {
        baseURI = _baseUri;
    }

    function flipSaleState() external onlyOwner {
        isSale = !isSale;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
