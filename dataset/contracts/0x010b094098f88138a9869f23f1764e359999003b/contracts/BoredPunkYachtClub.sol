// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BoredPunksYachtClub is
    ERC721A("Bored Punks Yacht Club", "BPYC"),
    DefaultOperatorFilterer,
    Ownable
{
    // Storage

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri = "ipfs://QmUdNpqxrWPqxofkp3V24PjRAwwoVZwFMVm8R48vM7Wn8R/";

    uint256 public cost = 0.004 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxPerWallet = 11;
    uint256 public maxFreePerWallet = 1;

    bool public paused = true;
    bool public revealed = false;

    // Constants

    address public constant ADMIN_ONE = 0xC0EE5401DbaDBcf2142B722d916eED9dDE03939D;
    address public constant ADMIN_TWO = 0xEf58d656c7A1710A0A83fC8B706B6b92a9364cDb;

    // Modifiers

    modifier mintCompliance(uint256 _mintAmount) {
        require(msg.sender == tx.origin, "No contracts allowed!");
        require(_mintAmount > 0, "You can't mint 0 punks!");
        require(
            _numberMinted(_msgSender()) + _mintAmount <= maxPerWallet,
            "You can't mint more than 11 punks per wallet!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Those damn punks took everything we had!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        uint256 totalCost = cost * _mintAmount;

        if (_numberMinted(_msgSender()) < maxFreePerWallet) {
            totalCost = totalCost - cost;
        }

        require(msg.value >= totalCost, "Hey PUNK! You've got to pay for that!");
        _;
    }

    // Main mint function

    function mint(
        uint256 _mintAmount
    ) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!paused, "Come back soon PUNK!");

        _safeMint(_msgSender(), _mintAmount);
    }

    // Metadata Reveal Override

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), uriSuffix))
                : "";
    }

    // Admin Functions

    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _safeMint(_receiver, _mintAmount);
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxPerWallet(uint256 max) public onlyOwner {
        maxPerWallet = max;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = ADMIN_ONE.call{value: address(this).balance / 2}("");
        require(success, "Transfer failed.");

        (bool secondSucces, ) = ADMIN_TWO.call{value: address(this).balance}("");
        require(secondSucces, "Second Transfer failed.");
    }

    // Opensea OperatorFilterer Overrides

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

    // Internal Overrides

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
