// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";

contract Meloguyz is ERC721A, Ownable, DefaultOperatorFilterer {
  using Address for address payable;

  error InvalidEtherValue();
  error MaxPerWalletOverflow();
  error TotalSupplyOverflow();
  error InvalidProof();

  struct MintRules {
    uint256 supply;
    uint256 maxPerWallet;
    uint256 freePerWallet;
    uint256 price;
  }

  modifier onlyWhitelist(bytes32[] calldata _proof, uint256 _freeQuantity) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, _freeQuantity))));

    if (!MerkleProof.verify(_proof, _merkleRoot, leaf)) {
      revert InvalidProof();
    }

    _;
  }

  MintRules public mintRules;
  string public baseTokenURI;

  bytes32 private _merkleRoot;

  constructor() ERC721A("Meloguyz", "MELO") {}

  /*//////////////////////////////////////////////////////////////
                         External getters
  //////////////////////////////////////////////////////////////*/

  function totalMinted() external view returns (uint256) {
    return _totalMinted();
  }

  function numberMinted(address _owner) external view returns (uint256) {
    return _numberMinted(_owner);
  }

  /*//////////////////////////////////////////////////////////////
                         Minting functions
  //////////////////////////////////////////////////////////////*/

  function mint(
    uint256 _quantity,
    uint256 _freeQuantity,
    bytes32[] calldata _proof
  ) external payable onlyWhitelist(_proof, _freeQuantity) {
    _customMint(_quantity, _freeQuantity);
  }

  function mint(uint256 _quantity) external payable {
    _customMint(_quantity, mintRules.freePerWallet);
  }

  /*//////////////////////////////////////////////////////////////
                      Owner functions
  //////////////////////////////////////////////////////////////*/

  function airdrop(address _to, uint256 _quantity) external onlyOwner {
    if (_totalMinted() + _quantity > mintRules.supply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(_to, _quantity);
  }

  function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setMintRules(MintRules calldata _mintRules) external onlyOwner {
    mintRules = _mintRules;
  }

  function setMerkleRoot(bytes32 _root) external onlyOwner {
    _merkleRoot = _root;
  }

  function withdraw() external onlyOwner {
    payable(owner()).sendValue(address(this).balance);
  }

  /*//////////////////////////////////////////////////////////////
                      Overriden ERC721A
  //////////////////////////////////////////////////////////////*/

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  /*//////////////////////////////////////////////////////////////
                      Internal functions
  //////////////////////////////////////////////////////////////*/

  function _customMint(uint256 _quantity, uint256 _freeQuantity) internal {
    uint256 _alreadyMinted = _numberMinted(msg.sender);
    uint256 _paidQuantity = _calculatePaidQuantity(_alreadyMinted, _quantity, _freeQuantity);

    if (_paidQuantity != 0 && msg.value < mintRules.price * _paidQuantity) {
      revert InvalidEtherValue();
    }

    if (_alreadyMinted + _quantity > mintRules.maxPerWallet) {
      revert MaxPerWalletOverflow();
    }

    if (_totalMinted() + _quantity > mintRules.supply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(msg.sender, _quantity);
  }

  function _calculatePaidQuantity(
    uint256 _alreadyMinted,
    uint256 _quantity,
    uint256 _freeQuantity
  ) internal pure returns (uint256) {
    uint256 _freeQuantityLeft = _alreadyMinted >= _freeQuantity ? 0 : _freeQuantity - _alreadyMinted;

    return _freeQuantityLeft >= _quantity ? 0 : _quantity - _freeQuantityLeft;
  }

  /*//////////////////////////////////////////////////////////////
                        DefaultOperatorFilterer
  //////////////////////////////////////////////////////////////*/

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
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
