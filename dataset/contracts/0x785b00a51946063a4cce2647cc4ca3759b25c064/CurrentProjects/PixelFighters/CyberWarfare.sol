// SPDX-License-Identifier: MIT

/*

                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                  ...                                     
                                                 ,dO0x;..                                 
                                                  'o0NNNKo.                               
                                                    c0XWWWKdo;.                           
                                         ....,c;   .'lOXXXNWMNOko'                        
                                     ..,oOOO0KXx,':xdlokKKKXNWMMWKd,'.                    
                                   .:xO0KNNNNNNXXXXKc.;xKKKKKXNWMMWWNOc.                  
                                  ;x0XXXXNNNNNNNNNNXkxOx:;o0KKKXNWMMMMWO:.                
                                 ,kXXXNNNNNNNNNNNXXNN0l.  'd0KKKKXNWMMMMNO,               
                                ;OXNNNNNNNNNNNNNXKKKXX0:   .oKKKKKKXWMMMMWx'              
                                :KNNNNNNNXKXNNNNNNK0KNXc  .:kKKKKKKXWMMMMMMO.             
                                .:kXNNNXXKOOKXXNNXKkO00l':x0KKKKKKKXWMMMMMM0'             
                                 .,oOKKxdddxOO0KXKkdolclk0KKKKKKKXNWMMMMMMMO'             
                .'.               ..'lo:;;;;;;:lxxo:;cokKKKKKKKXNWMMMMMMMW0c.             
                .;.             .''...',;,;;;;;,,,;:ok0KKKKKKXNWMMMMMMMWKo.               
                   .;'  ..      .:c:;;codddxkkxolcok0KKKXXXNWWMMMMMWNX0o.                 
                    . .;xOl,'.   .':clodxxxOKKK0000KXXXNWWWMMMWXOOOx;..                   
                        'loxKxc:cccokk0XXXXNNNNNNNNNWMMMMMMWOol'                          
                           .;c:ckNNWNWWMMMMMMMMMMMWWWWWXkoc:.                             
                                .';clld0XXXXXXXXXNOlokdl;.                                
                                  .;:,',,,,,,,,,;ll;'....                                 
                                .;:;...        .';:;.                                     
                                .'.             .'.                                       
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          
                                                                                          


*/

pragma solidity >=0.8.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract CyberWarfare is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;
  string public uriPrefix;
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerWallet;
  uint256 public maxFreeMintAmountPerWallet;
  uint256 public teamSupply;
  mapping(address => bool) freeMint;
  uint256 public publicMintCost;
  bool public paused = true;
  bool public revealed = true;

  /**
  @dev tokenId to team (1 = Cypress, 2 = Phoenix)
  */
  mapping(uint256 => uint256) public side;

  constructor(
      uint256 _maxSupply,
      uint256 _publicMintCost,
      uint256 _maxMintAmountPerWallet,
      uint256 _maxFreeMintAmountPerWallet,
      uint256 _teamSupply,
      string memory _uriPrefix
    )  ERC721A("Cyber Warfare", "CyWar")  {
        maxSupply = _maxSupply;
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
        maxFreeMintAmountPerWallet = _maxFreeMintAmountPerWallet;
        uriPrefix = _uriPrefix;
        teamSupply = _teamSupply;
        publicMintCost = _publicMintCost;
    _safeMint(msg.sender, 1);
  }

  function setParams(
    uint256 _maxSupply,
    uint256 _publicMintCost,
    uint256 _maxMintAmountPerWallet,
    uint256 _maxFreeMintAmountPerWallet,
    uint256 _teamSupply,
    string memory _uriPrefix
  ) public onlyOwner {
    maxSupply = _maxSupply;
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
    maxFreeMintAmountPerWallet = _maxFreeMintAmountPerWallet;
    uriPrefix = _uriPrefix;
    teamSupply = _teamSupply;
    publicMintCost = _publicMintCost;
  }

  /**
  @dev Check supply requirements
  */
  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply - teamSupply, 'Max Supply Exceeded!');
    _;
  }

  /**
  @dev mint a Cypress
  */
  function mintCypress(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {
    require(!paused, 'The portal is not open yet!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxMintAmountPerWallet, 'Max Limit per Wallet!');

    if(freeMint[_msgSender()]) {
      require(msg.value >= _mintAmount * publicMintCost, 'Insufficient Funds!');
    }
    else {
      require(msg.value >= (_mintAmount - 1) * publicMintCost, 'Insufficient Funds!');
      freeMint[_msgSender()] = true;
    }

    for (uint256 i=_currentIndex; i < _currentIndex+_mintAmount; i++) {
      side[i] = 1; // Blue
    }

    _safeMint(_msgSender(), _mintAmount);
  }

  /**
  @dev mint a Phoenix
  */

  function mintPhoenix(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {

    require(!paused, 'The Cyber War has not begun!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxMintAmountPerWallet, 'Max Limit per Wallet!');

    if(freeMint[_msgSender()]) {
      require(msg.value >= _mintAmount * publicMintCost, 'Insufficient Funds!');
    }
    else {
      require(msg.value >= (_mintAmount - 1) * publicMintCost, 'Insufficient Funds!');
      freeMint[_msgSender()] = true;
    }

    for (uint256 i=_currentIndex; i < _currentIndex+_mintAmount; i++) {
      side[i] = 2; // Red
    }

    _safeMint(_msgSender(), _mintAmount);
  }

  /**
  @dev tokenId to staking start time (0 = not staking).
  */
  mapping(uint256 => uint256) private stakingStarted;

  /**
  @dev Cumulative per-token staking, excluding the current period.
  */
  mapping(uint256 => uint256) private stakingTotal;

  /**
  @notice Returns the length of time, in seconds, that the NFT has
  staked.
  @dev staking is tied to a specific NFT, not to the owner, so it doesn't
  reset upon sale.
  @return staking Whether the NFT is currently staking. MAY be true with
  zero current staking if in the same block as staking began.
  @return current Zero if not currently staking, otherwise the length of time
  since the most recent staking began.
  @return total Total period of time for which the NFT has staked across
  its life, including the current period.
  */
  function stakingPeriod(uint256 tokenId)
      external
      view
      returns (
          bool staking,
          uint256 current,
          uint256 total
      )
  {
      uint256 start = stakingStarted[tokenId];
      if (start != 0) {
          staking = true;
          current = block.timestamp - start;
      }
      total = current + stakingTotal[tokenId];
  }

  /**
  @dev MUST only be modified by safeTransferWhileStaking(); if set to 2 then
  the _beforeTokenTransfer() block while staking is disabled.
    */
  uint256 private stakingTransfer = 1;

  /**
  @notice Transfer a token between addresses while the NFT is minting,
  thus not resetting the staking period.
    */
  function safeTransferWhilestaking(
      address from,
      address to,
      uint256 tokenId
  ) external {
      require(ownerOf(tokenId) == _msgSender(), "NFTs: Only owner");
      stakingTransfer = 2;
      safeTransferFrom(from, to, tokenId);
      stakingTransfer = 1;
  }

  /**
  @dev Block transfers while staking.
    */
  function _beforeTokenTransfers(
      address,
      address,
      uint256 startTokenId,
      uint256 quantity
  ) internal view override {
      uint256 tokenId = startTokenId;
      for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
          require(
              stakingStarted[tokenId] == 0 || stakingTransfer == 2,
              "NFTs: staking"
          );
      }
  }

  /**
  @dev Emitted when a NFT begins staking.
    */
  event staked(uint256 indexed tokenId);

  /**
  @dev Emitted when a NFT stops staking; either through standard means or
  by expulsion.
    */
  event Unstaked(uint256 indexed tokenId);

  /**
  @dev Emitted when a NFT is expelled from the nest.
    */
  event Expelled(uint256 indexed tokenId);

  /**
  @notice Whether staking is currently allowed.
  @dev If false then staking is blocked, but unstaking is always allowed.
    */
  bool public stakingOpen = false;

  /**
  @notice Toggles the `stakingOpen` flag.
    */
  function setStakingOpen(bool open) external onlyOwner {
      stakingOpen = open;
  }

  /// @notice Requires that msg.sender owns or is approved for the token.
  modifier onlyApprovedOrOwner(uint256 tokenId) {
      require(
          _ownershipOf(tokenId).addr == _msgSender() ||
              getApproved(tokenId) == _msgSender(),
          "ERC721ACommon: Not approved nor owner"
      );
      _;
  }

  /**
  @notice Changes the NFT's staking status.
  */
  function toggleStaking(uint256 tokenId)
      internal
      onlyApprovedOrOwner(tokenId)
  {
      uint256 start = stakingStarted[tokenId];
      if (start == 0) {
          require(stakingOpen, "NFTs: staking closed");
          stakingStarted[tokenId] = block.timestamp;
          emit staked(tokenId);
      } else {
          stakingTotal[tokenId] += block.timestamp - start;
          stakingStarted[tokenId] = 0;
          emit Unstaked(tokenId);
      }
  }

  /**
  @notice Changes the NFTs' staking statuss (what's the plural of status?
  statii? statuses? status? The plural of sheep is sheep; maybe it's also the
  plural of status).
  @dev Changes the NFTs' staking sheep (see @notice).
    */
  function toggleStaking(uint256[] calldata tokenIds) external {
      uint256 n = tokenIds.length;
      for (uint256 i = 0; i < n; ++i) {
          toggleStaking(tokenIds[i]);
      }
  }

  /**
  @notice Admin-only ability to expel a NFT from the nest.
  @dev As most sales listings use off-chain signatures it's impossible to
  detect someone who has staked and then deliberately undercuts the floor
  price in the knowledge that the sale can't proceed. This function allows for
  monitoring of such practices and expulsion if abuse is detected, allowing
  the undercutting bird to be sold on the open market. Since OpenSea uses
  isApprovedForAll() in its pre-listing checks, we can't block by that means
  because staking would then be all-or-nothing for all of a particular owner's
  NFTs.
    */
  function expelFromStaking(uint256 tokenId) external onlyOwner {
      require(stakingStarted[tokenId] != 0, "NFTs: not staked");
      stakingTotal[tokenId] += block.timestamp - stakingStarted[tokenId];
      stakingStarted[tokenId] = 0;
      emit Unstaked(tokenId);
      emit Expelled(tokenId);
  }


  function teamMint(address[] memory _staff_address) public onlyOwner payable {
    require(_staff_address.length <= teamSupply, '');
    for (uint256 i = 0; i < _staff_address.length; i ++) {
      _safeMint(_staff_address[i], 1);
    }
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
    ? string(abi.encodePacked(currentBaseURI, side[_tokenId].toString(), "/", _tokenId.toString(), uriSuffix))
    : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
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

  function setMintCost(uint256 _cost) public onlyOwner {
      publicMintCost = _cost;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setTeamAmount(uint256 _teamSupply) public onlyOwner {
    teamSupply = _teamSupply;
  }

  function withdraw() public onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  /**
  @dev OpenSea Default Operator royalties
  */

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
  public payable
  override
  onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}