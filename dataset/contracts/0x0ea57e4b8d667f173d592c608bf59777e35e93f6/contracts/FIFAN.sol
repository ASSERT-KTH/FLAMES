// SPDX-License-Identifier: MIT
/*
███████ ██ ███████  █████  ███    ██ 
██      ██ ██      ██   ██ ████   ██ 
█████   ██ █████   ███████ ██ ██  ██ 
██      ██ ██      ██   ██ ██  ██ ██ 
██      ██ ██      ██   ██ ██   ████ 
NFT Collections

https://fifan.xyz

By: Zlatan
*/

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract FIFAN is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public costBronze;
  uint256 public costSilver;
  uint256 public costGolden;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  bool public JackpotRevenue = false;
  bool public CollectorsClubRevenue = false;
  
  address public contractShieldCup;  
  address public jackpotAddress;
  address public collectorsClubAddress;
  address public team;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    address _team
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
    setTeamAddress(_team);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    if(_mintAmount == 3){
      require(msg.value >= costSilver * _mintAmount, 'Insufficient funds!');
      _;
    }else if(_mintAmount >= 5){
      require(msg.value >= costGolden * _mintAmount, 'Insufficient funds!');
      _;
    }else{
      require(msg.value >= costBronze * _mintAmount, 'Insufficient funds!');
      _;
    }
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setJackpotRevenue(bool _state) public onlyOwner {
    JackpotRevenue = _state;
  }

  function setCollectorsClubRevenue(bool _state) public onlyOwner {
    CollectorsClubRevenue = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    costBronze = _cost;
    costSilver = _cost - (_cost * 3/100); // 3% Discount
    costGolden = _cost - (_cost * 5/100); // 5% Discount
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setContractShield(address _shield) public onlyOwner{
    contractShieldCup = _shield;
  }

  function setJackpotContract(address _contract) public onlyOwner {
    jackpotAddress = _contract;
  }

  function setCollectorsClubContract(address _contract) public onlyOwner{
    collectorsClubAddress = _contract;
  }

  function setTeamAddress(address _team) public onlyOwner{
    team = _team;
  }

  function withdraw() public onlyOwner nonReentrant {

    // Jackpot & Collectors Club Value
    uint256 jackpotValue = address(this).balance * 20 / 1000; // = 20% ÷ 10 Wallets
    uint256 collectorsclubValue = (address(this).balance * 15 / 100); // = 20% ÷ 10 Wallets

    
    if(JackpotRevenue == true){
      (bool js, ) = payable(jackpotAddress).call{value: jackpotValue}('');
      require(js);
    }

    if(CollectorsClubRevenue == true){
      (bool js, ) = payable(collectorsClubAddress).call{value: collectorsclubValue}('');
      require(js);
    }

    (bool hs, ) = payable(team).call{value: address(this).balance}('');
    require(hs);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

}
