// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Reincarpo is Ownable, ERC721A, DefaultOperatorFilterer {
    // using Strings for uint256;
    
    //variables
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public per_wallet = 5;
    uint256 public constant FREE_PER_WALLET = 1;
    uint256 public cost = 4000000000000000;

    string public baseUri;
    // string public uriSuffix = ".json";

    bool public isPaused = false;

    constructor(string memory initUri) ERC721A("Reincarpo", "RNCRP") {
        baseUri = initUri;
    }

    //set

    function setMaxPerWallet(uint _per_wallet) external onlyOwner {
        per_wallet = _per_wallet;
    }

    function setCost(uint _cost) external onlyOwner {
        cost = _cost;
    }

    function changeBaseUri(string memory newURI) external onlyOwner {
        baseUri = newURI;
    }

    function startSale(bool state) external onlyOwner {
        isPaused = state;
    }

    //mint

    function publicMint(uint256 amount) external payable {
        require(
            isPaused,
            "Sale hasn't started yet"
        );
        require(
            cost * (amount - (balanceOf(msg.sender) == 0 ? FREE_PER_WALLET : 0)) <= msg.value,
            "Insufficient funds sent"
        );
        require(
            balanceOf(msg.sender) + amount <= per_wallet, 
            "Mint limit reached for this wallet"
        );
        require(
            totalSupply() + amount <= MAX_SUPPLY,
             "SOLD OUT"
        );
        require(
            msg.sender == tx.origin,
            "Contracts not allowed"
        );
        
        _mint(msg.sender, amount);
    }

    //airdrop

    function ownerMint(uint256 amount, address[] memory recipients) external payable onlyOwner {
        require(
            totalSupply() + amount * recipients.length <= MAX_SUPPLY,
            "SOLD OUT"
        );
        for (uint32 i = 0; i < recipients.length;){
            _mint(recipients[i], amount);

            unchecked {
                i++;
            }
        }
    }

    //BaseURI

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    //TokenURI

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseUri).length != 0 ? string(abi.encodePacked(baseUri, _toString(tokenId))) : '';
    }

    //FirstTokenId

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //Withdraw

    function withdraw() external onlyOwner {
        (bool res, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(res);
    }

    //Operator

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

