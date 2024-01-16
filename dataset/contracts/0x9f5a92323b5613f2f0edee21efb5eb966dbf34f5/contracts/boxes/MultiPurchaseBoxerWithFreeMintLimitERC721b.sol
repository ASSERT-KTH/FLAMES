// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../tokens/interfaces/IERC721b.sol";

import "../checkout/interfaces/ICheckouter.sol";
import "../checkout/interfaces/IERC20Checkouter.sol";
import "../checkout/interfaces/IETHCheckouter.sol";

import "../utils/WhitelistWithLimit.sol";
import "../checkout/counters/ETHAndERC20CheckoutCounter.sol";

import "hardhat/console.sol";

contract MultiPurchaseBoxerWithFreeMintLimitERC721b is Context, Ownable, ETHAndERC20CheckoutCounter {
    using SafeMath for uint256;

    struct PriceInfo {
        address token;
        uint256 price;
        ICheckouter.BillingType billingType;
    }

    event BoxerInited (
        address nftAddress,
        uint256 capacity,
        uint256 freeMintLimit,
        PriceInfo priceInfo
    );

    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address public nftAddress;

    uint256 public capacity;
    PriceInfo public priceInfo;
    mapping(address => uint256) public freeMinted;
    uint256 public freeMintLimit;

    modifier onlyCapacityEnoughBatch(uint256 _amount) {
        require(capacity >= _amount, "not enough");
        _;
    }

    constructor() ETHAndERC20CheckoutCounter() {}

    function setBasicInfo(address _nftAddress, uint256 _capacity, PriceInfo memory _priceInfo, uint256 _freeMintLimit) public onlyOwner {
        nftAddress = _nftAddress;
        capacity = _capacity;
        priceInfo = _priceInfo;
        freeMintLimit = _freeMintLimit;

        emit BoxerInited(nftAddress, capacity, freeMintLimit, priceInfo);
    }

    function freeMint(uint256 _amount) public onlyCapacityEnoughBatch(_amount) {
        require(freeMinted[msg.sender] + _amount <= freeMintLimit, "free mint exceed limit");

        _metaTrade(_amount);
        freeMinted[msg.sender] = freeMinted[msg.sender] + _amount;
    }

    function _metaTrade(uint256 _amount) private {
        IERC721b(nftAddress).mint(_msgSender(), _amount);
        capacity = capacity.sub(_amount);
    }
    
    function _refundRemainEth(uint256 refundAmount) private {
        if (refundAmount > 0) {
            (bool sent, ) = payable(_msgSender()).call{value: refundAmount}("");
            require(sent, "refund fail");
        }
    }
}