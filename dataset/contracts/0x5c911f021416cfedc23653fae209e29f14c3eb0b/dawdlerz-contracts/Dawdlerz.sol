pragma solidity ^0.8.4;

import './ERC721A.sol';

contract Dawdlerz is ERC721A {

  address private owner;
  uint256 private constant MAX_SUPPLY = 8888;
  uint256 private constant MAX_TEAM_MINT = 250;
  uint256 private constant MAX_TOKEN_PER_MINT = 20;
  uint256 private COUNTER_TEAM_MINT = 0;
  uint256 public MINT_PRICE = 50000000000000000;
  string private _baseTokenURI = "https://dawdlerz.com/metadata/";
  bool public isMintAllow = false;

  constructor () ERC721A('Dawdlerz', 'DZ') {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'Only owner');
    require(msg.sender == tx.origin, "Do not use contracts");
    _;
  }

  function mint(uint256 quantity) public payable {
    require(quantity <= MAX_TOKEN_PER_MINT, 'Max token per mint reached');
    require(_totalMinted() + quantity <= MAX_SUPPLY, 'Max supply reached');
    require(msg.value >= MINT_PRICE * quantity, 'Insufficient funds');
    _mint(msg.sender, quantity);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function baseURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    string memory getBaseURI = _baseURI();
    return bytes(getBaseURI).length != 0 ? string(abi.encodePacked(getBaseURI, _toString(tokenId))) : '';
  }

  function setBaseURI(string calldata newBaseURI) onlyOwner external {
    _baseTokenURI = newBaseURI;
  }

  function setMintPrice(uint256 newPrice) onlyOwner external {
    MINT_PRICE = newPrice;
  }

  function setOwner(address newOwner) onlyOwner external {
    require(newOwner != address(0), "Zero address");
    owner = newOwner;
  }

  function withdrawMoney() external onlyOwner  {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function mint_team(address to, uint256 quantity) public onlyOwner {
    require(_totalMinted() + quantity <= MAX_SUPPLY, 'Max supply reached');
    require(COUNTER_TEAM_MINT + quantity <= MAX_TEAM_MINT, 'Max team mint reached');
    _mint(to, quantity);
  }

  function setMintAllow() external onlyOwner {
    isMintAllow = !isMintAllow;
  }
}