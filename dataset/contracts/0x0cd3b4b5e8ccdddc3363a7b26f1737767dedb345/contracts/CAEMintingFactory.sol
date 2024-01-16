// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ChampionsAscensionElemental.sol";

contract CAEMintingFactory is Pausable, AccessControl {

  /// @notice emitted when the parameters are set for a claim list
  event ListClaimParametersSet(
    uint8 listClaimIndex, // claim list number (value of ListClaimEnum) for which parameters were set
    uint40 start,         // claim period start time in epoch seconds
    uint40 duration,      // claim period duration in seconds
    uint32 maxPerAddress, // maximum claims per address
    bytes32 merkleRoot    // Merkle root of address allowed to claim. If 0 any address may claim
  );

  /// @notice emitted when the parameters are set for a the public mint
  event PublicMintParametersSet(
    uint40 start,             // claim period start time in epoch seconds
    uint40 duration,          // claim period duration in seconds
    uint32 maxPerTransaction  // maximum claims per transaction
  );

  /// @notice the different kinds of minting
  enum MintSourceEnum {
    AIRDROP,
    CLAIM_LIST_PRIME,
    CLAIM_LIST_TIER1,
    CLAIM_LIST_TIER2,
    PUBLIC_MINT
  }

  /// @notice emitted when a batch of elementals are airdropped to a batch of address
  event AirdropBatch(
    uint addressCount, // number of addresses to which a batch is dropped
    uint number // total number of elementals dropped across all addresses
  );

  /// emitted when a batch of elementals is minted either for claim or airdrop
  event MintBatch(
    address to,
    uint32 number,
    uint startId,    // ID of first token minted in batch
    MintSourceEnum mintSource
  );


  bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
  bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINT_ADMIN_ROLE = keccak256("MINT_ADMIN_ROLE");

  /// @notice the different phases/kinds of claim list
  enum ListClaimEnum {
    PRIME,  // 0
    TIER1,  // 1
    TIER2   // 2
  }
  uint8 public constant NUM_LISTS = 3; // uint(TIER2) + 1
  
  struct ListClaimParams {
    uint40 start; // time of event start in seconds since the epoch
    uint40 duration; // duration of event in seconds
    uint32 maxPerAddress; // max number of Elementals claimable by member
    bytes32 merkleRoot; // merkle tree root of addresses in list
  }

  struct PublicMintParams {
    uint40 start; // time of event start in seconds since the epoch
    uint40 duration; // duration of event in seconds
    uint32 maxPerTransaction; // max number of Elementals claimable in one transaction
  }

  /////////////////////////////////////////////////////////////////////////////
  // State
  /////////////////////////////////////////////////////////////////////////////

  /// @dev Contract deployer is payable for self destruct
  address payable public immutable deployer;

  /// @dev Elemental NFT contract
  address public immutable nftAddress;
  ChampionsAscensionElemental private immutable _elemental;

  /// @notice List claim parameters
  ListClaimParams[NUM_LISTS] public listClaimParams;

  /// @notice List claim counts
  mapping(address => uint8)[NUM_LISTS] public claimCounts; // number claimed to an address for each list

  /// @notice Public params
  PublicMintParams public publicMintParams;

  /////////////////////////////////////////////////////////////////////////////
  // Modifiers
  /////////////////////////////////////////////////////////////////////////////

  function _blocktimeBetween(uint start, uint duration) internal view returns (bool) {
    return start <= block.timestamp && block.timestamp < (start + duration);
  }

  function listClaimActive(ListClaimEnum listChoice) public view returns (bool) {
    ListClaimParams memory list = _listClaimParamsForEnumValue(listChoice);
    return _blocktimeBetween(list.start, list.duration);
  }

  function publicMintActive() public view returns (bool) {
    return _blocktimeBetween(publicMintParams.start, publicMintParams.duration);
  }

  /////////////////////////////////////////////////////////////////////////////
  // Constructor
  /////////////////////////////////////////////////////////////////////////////

  constructor(address _nftAddress) {
    deployer = payable(msg.sender);
    require(_nftAddress != address(0), "_nftAddress is zero address");
    nftAddress = _nftAddress;
    _elemental = ChampionsAscensionElemental(_nftAddress);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(AIRDROP_ROLE, msg.sender);
    _grantRole(MINT_ADMIN_ROLE, msg.sender);
  }

  /////////////////////////////////////////////////////////////////////////////
  // External open-access functions
  /////////////////////////////////////////////////////////////////////////////

  function isInClaimList(ListClaimEnum listChoice, address _address, bytes32[] calldata _proof)
      external
      view
      returns (bool)
  {
    ListClaimParams memory list = _listClaimParamsForEnumValue(listChoice);
    bytes32 merkleRoot = list.merkleRoot;
    return _verify(merkleRoot, _leaf(_address), _proof);
  }

  /**
   * @notice claim and mint as member of a claim list
   * @param listChoice the claim list
   * @param numToMint the number to mint
   * @param proof the Merkle proof for the address claiming and minting. It must be the message sender (msg.sender)
   */
  function listClaimAndMint(ListClaimEnum listChoice, uint8 numToMint, bytes32[] calldata proof) external
  {
    ListClaimParams memory params = _listClaimParamsForEnumValue(listChoice);
    uint listClaimIndex = _listClaimIndexForEnumValue(listChoice);
    require(listClaimActive(listChoice), "list claim is not active");
    require(_verify(params.merkleRoot, _leaf(msg.sender), proof), "invalid merkle proof");
    claimCounts[listClaimIndex][msg.sender] += numToMint;
    require(
        claimCounts[listClaimIndex][msg.sender] <= params.maxPerAddress,
        "exceeds maximum claims per address"
    );
    MintSourceEnum mintSource = 
      listChoice == ListClaimEnum.PRIME ? MintSourceEnum.CLAIM_LIST_PRIME : 
      listChoice == ListClaimEnum.TIER1 ? MintSourceEnum.CLAIM_LIST_TIER1 : 
      MintSourceEnum.CLAIM_LIST_TIER2; 
    _doMint(msg.sender, numToMint, mintSource);
  }

  function publicMint(uint8 numToMint) external {
    require(publicMintActive(), "public mint is not active");
    require(numToMint <= publicMintParams.maxPerTransaction, "exceeds maximum claims per transaction");
    _doMint(msg.sender, numToMint, MintSourceEnum.PUBLIC_MINT);
  }

  /////////////////////////////////////////////////////////////////////////////
  // External administrative functions
  /////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Airdrop minting.
   */
  function airdrop(address[] calldata to, uint32[] calldata numberToMint) external onlyRole(AIRDROP_ROLE) {
    require(to.length == numberToMint.length, "to and numberToMint length mismatch");
    require(to.length > 0);
    uint total = 0;
    for (uint32 e = 0; e < to.length; e++) {
      total += numberToMint[e];
      _doMint(to[e], numberToMint[e], MintSourceEnum.AIRDROP);
    }
    emit AirdropBatch(to.length, total);
  }

  /**
   * @notice Set the parameters managing one of the claim lists.
   * @param _listChoice the list whose parameters are being set
   * @param _params the parameters of the claim list
   */
  function setListClaimParameters(
      ListClaimEnum _listChoice,
      ListClaimParams calldata _params
  ) external onlyRole(MINT_ADMIN_ROLE) {
    uint8 listIndex = uint8(_listChoice);
    require(listIndex < NUM_LISTS, "claim list index out of range");
    listClaimParams[listIndex] = _params;
    emit ListClaimParametersSet(
        listIndex,
        _params.start,
        _params.duration,
        _params.maxPerAddress,
        _params.merkleRoot
    );
  }

  /**
   * @notice Set the parameters managing public mint.
   * @param _params the parameters
   */
  function setPublicMintParameters(
      PublicMintParams calldata _params
  ) external onlyRole(MINT_ADMIN_ROLE) {
    publicMintParams = _params;
    emit PublicMintParametersSet(
        _params.start,
        _params.duration,
        _params.maxPerTransaction
    );
  }

  /**
   * @notice Disables minting for any claim list (scheduled or in progress)
   * @dev Does not extend any claim duration to compensate for the time paused
   */
  function pause() external onlyRole(MINT_ADMIN_ROLE) {
      _pause();
  }

  /**
   * @notice Resumes minting for any claim list (scheduled or in progress)
   * @dev Does not extend any claim duration to compensate for the time paused
   */
  function unpause() external onlyRole(MINT_ADMIN_ROLE) {
      _unpause();
  }

  /////////////////////////////////////////////////////////////////////////////
  // Internal functions
  /////////////////////////////////////////////////////////////////////////////

  function _leaf(address mintTo) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(mintTo));
  }

  function _verify(bytes32 merkleRoot, bytes32 leaf, bytes32[] memory proof)
      internal
      pure
      returns (bool)
  {
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }

  function _listClaimIndexForEnumValue(ListClaimEnum listChoice) internal pure returns(uint) {
    require(uint(listChoice) < NUM_LISTS, "claim list index out of bounds");
    return uint(listChoice); 
  }

  function _listClaimParamsForEnumValue(ListClaimEnum listChoice) internal view returns(ListClaimParams memory) {
    ListClaimParams memory list = listClaimParams[_listClaimIndexForEnumValue(listChoice)];
    return list;
  }

  function _doMint(address to, uint32 numToMint, MintSourceEnum mintSource) private whenNotPaused {
      ChampionsAscensionElemental elemental = ChampionsAscensionElemental(nftAddress);
      emit MintBatch(to, numToMint, elemental.totalMinted() + 1, mintSource);
      elemental.mint(to, numToMint);
  }

  function selfDestruct() external onlyRole(DEPLOYER_ROLE) {
      selfdestruct(deployer);
  }

}