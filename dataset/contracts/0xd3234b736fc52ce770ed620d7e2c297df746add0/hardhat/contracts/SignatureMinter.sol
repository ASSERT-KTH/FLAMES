// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import '@openzeppelin/contracts/utils/structs/BitMaps.sol';

import './IMintable.sol';

contract SignatureMinter is Ownable {
  using BitMaps for BitMaps.BitMap;

  IMintable _token;
  address _signerAddress;

  BitMaps.BitMap _usedNonces;

  constructor(address tokenAddress) {
    _token = IMintable(tokenAddress);
  }

  function nonceUsed(uint256 nonce) external view returns (bool) {
    return _usedNonces.get(nonce);
  }

  function mint(
    address to,
    uint256 tokenId,
    uint256 amount,
    uint256 nonce,
    bytes calldata signature
  ) external {
    require(!_usedNonces.get(nonce), 'Nonce already used');
    require(
      _validateSignature(
        to,
        _asSingletonArray(tokenId),
        _asSingletonArray(amount),
        nonce,
        signature
      ),
      'Invalid signature'
    );

    _usedNonces.set(nonce);
    _token.mint(to, tokenId, amount);
  }

  function mintBatch(
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    uint256 nonce,
    bytes calldata signature
  ) external {
    require(!_usedNonces.get(nonce), 'Nonce already used');
    require(_validateSignature(to, tokenIds, amounts, nonce, signature), 'Invalid signature');

    _usedNonces.set(nonce);
    _token.mintBatch(to, tokenIds, amounts);
  }

  function adminMint(
    address to,
    uint256 tokenId,
    uint256 amount
  ) external onlyOwner {
    _token.mint(to, tokenId, amount);
  }

  function adminMint(
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) external onlyOwner {
    _token.mintBatch(to, tokenIds, amounts);
  }

  function setTokenAddress(address tokenAddress) external onlyOwner {
    _token = IMintable(tokenAddress);
  }

  function setSignerAddress(address signerAddress) external onlyOwner {
    _signerAddress = signerAddress;
  }

  function _validateSignature(
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    uint256 nonce,
    bytes calldata signature
  ) internal view virtual returns (bool) {
    bytes32 tokenHash = keccak256(abi.encodePacked(tokenIds));
    bytes32 amountHash = keccak256(abi.encodePacked(amounts));
    bytes32 dataHash = keccak256(abi.encodePacked(tokenHash, amountHash, nonce, to));
    bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

    return SignatureChecker.isValidSignatureNow(_signerAddress, message, signature);
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}
