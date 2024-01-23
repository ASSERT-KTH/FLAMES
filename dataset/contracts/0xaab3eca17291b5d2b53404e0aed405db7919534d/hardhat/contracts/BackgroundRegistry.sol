// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/structs/BitMaps.sol';

import './IERC1155Burnable.sol';
import './IBackgroundValidator.sol';

contract BackgroundRegistry is Ownable {
  struct BackgroundData {
    uint96 current;
    uint96 prev;
    uint64 timestamp;
  }

  event BackgroundChange(
    uint256 indexed tokenId,
    uint256 indexed backgroundId,
    uint256 indexed prevBackgroundId
  );

  event DefaultModeChange(uint256 indexed tokenId, bool mode);

  using BitMaps for BitMaps.BitMap;

  IERC721 public tokens;
  IERC1155Burnable public backgrounds;

  IBackgroundValidator public validator;

  mapping(uint256 => BackgroundData) _tokenBackgrounds;
  BitMaps.BitMap _defaultMode;

  // Let token owners revert changes within this time window.
  // The main reason for allowing reverts is to counter bad actors who
  // change/clear a valuable background just before a token sale
  uint256 public revertWindow = 10 minutes;

  modifier onlyApproved(uint256 tokenId) {
    require(_isApprovedOrOwner(msg.sender, tokenId), 'Caller is not token owner nor approved');
    _;
  }

  constructor(address tokenAddress, address backgroundAddress) {
    tokens = IERC721(tokenAddress);
    backgrounds = IERC1155Burnable(backgroundAddress);
  }

  function background(uint256 tokenId) external view returns (uint256) {
    return _tokenBackgrounds[tokenId].current;
  }

  function backgroundData(uint256 tokenId) external view returns (BackgroundData memory) {
    return _tokenBackgrounds[tokenId];
  }

  function defaultMode(uint256 tokenId) external view returns (bool) {
    return _defaultMode.get(tokenId);
  }

  function applyBackground(uint256 tokenId, uint256 backgroundId) external onlyApproved(tokenId) {
    require(backgroundId > 0 && backgroundId < 2**96, 'Unsupported background id');
    require(_isValidCombination(tokenId, backgroundId), 'Invalid combination');

    BackgroundData storage bg = _tokenBackgrounds[tokenId];
    require(bg.current != backgroundId, 'Background already applied');
    require(block.timestamp >= bg.timestamp + revertWindow, 'Too soon since last change');

    bg.prev = bg.current;
    bg.current = uint96(backgroundId);
    bg.timestamp = uint64(block.timestamp);

    emit BackgroundChange(tokenId, bg.current, bg.prev);

    backgrounds.burn(msg.sender, backgroundId, 1);
  }

  function clearBackground(uint256 tokenId) external onlyApproved(tokenId) {
    BackgroundData storage bg = _tokenBackgrounds[tokenId];
    require(block.timestamp >= bg.timestamp + revertWindow, 'Too soon since last change');

    bg.prev = bg.current;
    bg.current = 0;
    bg.timestamp = uint64(block.timestamp);

    emit BackgroundChange(tokenId, bg.current, bg.prev);
  }

  function revertBackground(uint256 tokenId) external onlyApproved(tokenId) {
    BackgroundData storage bg = _tokenBackgrounds[tokenId];
    require(block.timestamp < bg.timestamp + revertWindow, 'Too long since last change');

    (bg.prev, bg.current) = (bg.current, bg.prev);
    bg.timestamp = uint64(block.timestamp);

    emit BackgroundChange(tokenId, bg.current, bg.prev);
  }

  function toggleDefaultMode(uint256 tokenId) external onlyApproved(tokenId) {
    bool mode = !_defaultMode.get(tokenId);

    _defaultMode.setTo(tokenId, mode);

    emit DefaultModeChange(tokenId, mode);
  }

  function isValidCombination(uint256 tokenId, uint256 backgroundId) external view returns (bool) {
    return _isValidCombination(tokenId, backgroundId);
  }

  function setTokenAddress(address tokenAddress) external onlyOwner {
    tokens = IERC721(tokenAddress);
  }

  function setBackgroundAddress(address backgroundAddress) external onlyOwner {
    backgrounds = IERC1155Burnable(backgroundAddress);
  }

  function setValidatorAddress(address validatorAddress) external onlyOwner {
    validator = IBackgroundValidator(validatorAddress);
  }

  function setRevertWindow(uint256 revertWindow_) external onlyOwner {
    revertWindow = revertWindow_;
  }

  function _isValidCombination(uint256 tokenId, uint256 backgroundId) internal view returns (bool) {
    return address(validator) == address(0) || validator.isValidCombination(tokenId, backgroundId);
  }

  // Check whether `operator` is allowed to manage `tokenId`.
  function _isApprovedOrOwner(address operator, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    address owner = tokens.ownerOf(tokenId);
    return (operator == owner ||
      tokens.isApprovedForAll(owner, operator) ||
      tokens.getApproved(tokenId) == operator);
  }
}
