// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {OperatorFilterer} from "operator-filter-registry/src/OperatorFilterer.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract GigaKen is ERC721A, Pausable, OperatorFilterer, Ownable2Step {
    string public baseURI;
    uint256 public MAX_SUPPLY = 888;
    uint256 public MAX_MINT_PER_WALLET = 1;
    uint256 public maxMintPerTx = 1;
    uint256 public MINT_PRICE;
    
    mapping(address => uint) public mintCount;

    constructor(
        string memory _baseUri,
        uint256 priceInWEI,
        address operatorFilterer
    ) ERC721A("GigaKen", "GK") OperatorFilterer(operatorFilterer, true) {
        baseURI = _baseUri;
        MINT_PRICE = priceInWEI;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet) public onlyOwner {
        MAX_MINT_PER_WALLET = _maxMintPerWallet;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        MINT_PRICE = _mintPrice;
    }
    
    function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address to, uint256 amount) external payable whenNotPaused {
        unchecked {
            require(totalSupply() + amount <= MAX_SUPPLY, "Max supply reached");
            require(
                mintCount[to] + amount <= MAX_MINT_PER_WALLET,
                "Max mint per wallet reached"
            );
            require(amount <= maxMintPerTx, "Max mint per tx reached");
            require(msg.value == MINT_PRICE * amount, "Insufficient funds");
            mintCount[to] += amount;
            _mint(to, amount);
        }
    }
    
    function airdrop(address[] memory to, uint256 tokenAmount) external onlyOwner {
        for (uint i = 0; i < to.length; i++) {
            _mint(to[i], tokenAmount);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw(address payable to) public onlyOwner {
        // get the amount of Ether stored in this contract
        uint256 amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
    
    // Opensea overiding functions
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
}
