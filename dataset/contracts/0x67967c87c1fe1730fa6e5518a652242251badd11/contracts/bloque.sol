// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./src/ERC721A.sol";
import "./src/DefaultOperatorFilterer.sol";

error ExceedsMaxSupply();
error ExceedsLimit();
error SaleClose();
error InvalidOrigin();
error InvalidToken();
error Failed();
error InsufficientFunds();

contract bloque is ERC721A, Ownable, DefaultOperatorFilterer {
    bool public sale = false;
    string public baseURI = "https://pm.infura-ipfs.io/ipfs/QmdNNamLZAwG23DWYQ3r533jvBuQ4nPDUJ77UXuV951CMb/meta/";
    uint128 public constant maxBlock = 1111;
    uint128 public constant maxWallet = 5;
    uint128 public constant maxFree = 100;
    uint128 public price = 0.0069 ether;

    constructor() ERC721A("Bloque", "livingbloque") { _mint(msg.sender, 1);}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 amt) external payable {
        if(!sale) revert SaleClose();
        if(tx.origin != msg.sender) revert InvalidOrigin();
        if (_totalMinted() + amt > maxBlock) revert ExceedsMaxSupply();
        if(_numberMinted(msg.sender) + amt > maxWallet) revert ExceedsLimit();
        if(_totalMinted() + amt > maxFree){ if(msg.value < amt * price) revert InsufficientFunds();}
        _mint(msg.sender, amt);
    }

    function setPrice(uint128 amt) public onlyOwner {
        price = amt;
    }

    function setBaseURI(string calldata _url) public onlyOwner {
        baseURI = _url;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if(!success) revert Failed();
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if(!_exists(tokenId)) revert InvalidToken();
        return string(abi.encodePacked(baseURI,_toString(tokenId), ".json"));
    }

    function toggle() external onlyOwner {
        sale = !sale;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
        public
        payable
        override 
        onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from){
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId, data);
    }
}