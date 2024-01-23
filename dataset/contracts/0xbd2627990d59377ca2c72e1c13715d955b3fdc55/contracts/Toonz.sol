//SPDX-License-Identifier: MIT
//  _____ ___   ___  _   _ _____
// |_   _/ _ \ / _ \| \ | |__  /
//   | || | | | | | |  \| | / /
//   | || |_| | |_| | |\  |/ /_
//   |_| \___/ \___/|_| \_/____|

pragma solidity ^0.8.8;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

error SaleNotActive();
error MintLimitExceeded();
error InsufficientPayment();
error FreeMintLimitReached();
error MaxMintPerWalletExceeded();

contract Toonz is ERC721A, OperatorFilterer, Ownable {
    uint256 public MAX_SUPPLY = 3333;
    uint256 public MAX_PER_WALLET = 10;
    uint256 public PRICE = 0.004 ether;
    bool public saleActive = false;
    bool public operatorFilteringEnabled;
    string public baseURI;

    modifier noContract() {
        require(tx.origin == msg.sender, "Contracts not allowed to mint");
        _;
    }

    constructor(string memory baseURI_) ERC721A("Toonz", "TOONZ") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        baseURI = baseURI_;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function freeMint() external {
        if (!saleActive) revert SaleNotActive();
        if (_totalMinted() + 1 > MAX_SUPPLY) revert MintLimitExceeded();
        if (_getAux(msg.sender) != 0) revert FreeMintLimitReached();
        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
    }

    function mint(uint256 amount) external payable {
        if (!saleActive) revert SaleNotActive();
        if (_totalMinted() + amount >= MAX_SUPPLY) revert MintLimitExceeded();
        if (amount > MAX_PER_WALLET) revert MaxMintPerWalletExceeded();
        if (msg.value < PRICE * amount) revert InsufficientPayment();
        _mint(msg.sender, amount);
    }

    function withdraw() external onlyOwner {
        (bool hs, ) = payable(0x4d382CA0bB475f76c90bDd3D1e254Baa6BB36E9b).call{
            value: (address(this).balance * 50) / 100
        }("");
        require(hs);

        (bool os, ) = payable(0xcf9f5Ac852BF0a0E5a70D11B32F55B1f2aB04470).call{
            value: address(this).balance
        }("");
        require(os);
    }
}
