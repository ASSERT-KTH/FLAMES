// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Zliens is ERC721A, Ownable  {

  enum SalePhase {
        Locked,
        Whitelist,
        Public
    }
  
  SalePhase public phase = SalePhase.Locked;
  
  uint256 public cost = 0.003 ether;
  uint256 public maxSupply = 6969;
  uint256 public maxPerWallet = 5;
  uint256 public freeMintSupply = 6969;
  string public baseURI;
  address public couponSigner;

  struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

  enum CouponType {
    Whitelist
	}

  error PublicSaleNotActive();
  error WhitelistSaleNotActive();
  error MaxSupplyReached();
  error MaxPerWalletReached();
  error MaxPerTxReached();
  error NotEnoughETH();
  error NoContractMint();
  error InvalidCoupon();

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721A(_name, _symbol) payable {
    couponSigner = 0x3F693fcf465f3Ddb48479737c987FD9cB936100B;
    baseURI = "ipfs://bafybeicr7opufrsedtqqammfbykgmvrzwijketyb2zpcyjqnihomgexi4u/";
  }

  modifier mintCompliance(uint256 _amount) {
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    if (tx.origin != msg.sender) revert NoContractMint();
    if (_numberMinted(msg.sender) + _amount > maxPerWallet) revert MaxPerWalletReached();
    _;
  }

  function setCouponSigner(address couponSigner_) external onlyOwner {
    couponSigner = couponSigner_;
  }

	function _isVerifiedCoupon(bytes32 digest_, Coupon memory coupon_) internal view returns (bool) {
		address signer = ecrecover(digest_, coupon_.v, coupon_.r, coupon_.s);
    require(signer != address(0), 'Zero Address');
		return signer == couponSigner;
	}

  //MINT
  function whitelistMint(uint256 _amount, Coupon memory _coupon) external payable mintCompliance(_amount) {
    if (phase != SalePhase.Whitelist) revert WhitelistSaleNotActive();
    bytes32 digest = keccak256(
			abi.encode(CouponType.Whitelist, msg.sender)
		);
    if (!(_isVerifiedCoupon(digest, _coupon))) revert InvalidCoupon();

    uint256 paidMints = _amount;
    if (_numberMinted(msg.sender) == 0) {
        paidMints -= 1;
    }
    if (msg.value < cost * paidMints) revert NotEnoughETH();
    _mint(msg.sender, _amount);
  }

  function publicMint(uint256 _amount) external payable mintCompliance(_amount) {
    if (phase != SalePhase.Public) revert WhitelistSaleNotActive();
    if (msg.value < cost * _amount) revert NotEnoughETH();
    _mint(msg.sender, _amount);
  }

  function ownerMint(uint256 _amount) external onlyOwner {
    if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
    _mint(msg.sender, _amount);
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  function setMaxMint(uint256 _max) external onlyOwner {
    maxPerWallet = _max;
  }

  function setSalePhase(SalePhase _phase) external onlyOwner {
    phase = _phase;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  //METADATA
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setBaseURI(string calldata _newURI) external onlyOwner {
    baseURI = _newURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  //WITHDRAW
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}