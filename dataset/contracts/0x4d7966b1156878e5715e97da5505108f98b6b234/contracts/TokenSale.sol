// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TokenSale is Ownable {
    using SafeERC20 for IERC20;
    uint private constant BP = 10000;

    IERC20 public token;
    uint public startSaleTime;
    uint public endSaleTime;
    uint public startTokensUnlock;
    uint public endTokensUnlock;
    uint public totalTokenAmount;
    uint public bonusBp = 0;
    uint public isSaleFailed = 0;
    mapping(address user => uint amount) public usersDepositRaw;
    // Amount of token shares per user
    mapping(address user => uint amount) public usersDepositWithBonus;
    // Total amount of token shares
    uint public totalDepositedWithBonus = 0;
    // Amount of tokens claimed per user
    mapping(address user => uint amount) public alreadyClaimedTokens;

    event Deposit(address user, uint amount, uint amountWithBonus);
    event Claimed(uint amount, uint when);

    function init(
        IERC20 _token,
        uint tokenAmount,
        uint _startSaleTime,
        uint _endSaleTime,
        uint _startTokensUnlock,
        uint _endTokensUnlock
    ) external onlyOwner {
        require(block.timestamp < _startSaleTime, "startSaleTime is not in future");
        require(_startSaleTime < _endSaleTime, "startSaleTime >= endSaleTime");
        require(_endSaleTime < _startTokensUnlock, "endSaleTime >= startTokensUnlock");
        require(_startTokensUnlock < _endTokensUnlock, "start unlock >= end unlock");
        require(address(token) == address(0), "Already initialized");
        token = _token;

        startSaleTime = _startSaleTime;
        endSaleTime = _endSaleTime;
        startTokensUnlock = _startTokensUnlock;
        endTokensUnlock = _endTokensUnlock;

        totalTokenAmount = tokenAmount;

        token.safeTransferFrom(msg.sender, address(this), tokenAmount);
    }

    /**
     * @dev Throws if called when the sale is not marked as failed.
     */
    modifier whenFail() {
        require(isSaleFailed == 1, "Sale is not failed");
        _;
    }

    /**
     * @dev Throws if called before the sale concluded successfully.
     */
    modifier whenSuccess() {
        require(isSaleFailed == 0, "Sale is failed");
        require(block.timestamp >= startTokensUnlock, "Not before vesting starts");
        _;
    }

    /**
     * @notice Sets new bonus basis points
     */
    function setBonusBp(uint _bonusBp) external onlyOwner {
        bonusBp = _bonusBp;
    }

    /**
     * @notice Allows anyone to buy part of the tokens on sale with Ether
     */
    function deposit() external payable {
        require(block.timestamp >= startSaleTime, "Deposit is not yet available");
        require(block.timestamp < endSaleTime, "Deposit is no longer available");
        usersDepositRaw[msg.sender] += msg.value;
        uint depositWithBonus = msg.value + (msg.value * bonusBp) / BP;
        usersDepositWithBonus[msg.sender] += depositWithBonus;
        totalDepositedWithBonus += depositWithBonus;
        emit Deposit(msg.sender, msg.value, depositWithBonus);
    }

    /**
     * @notice Allows admin to collect payment for the sold tokens.
     */
    function withdraw() external onlyOwner whenSuccess {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Transfer failed");
    }

    function claim() external whenSuccess {
        uint amount = getAvailableToClaim(msg.sender);

        alreadyClaimedTokens[msg.sender] += amount;
        token.safeTransfer(msg.sender, amount);
        emit Claimed(amount, block.timestamp);
    }

    function setStartSaleTime(uint _startSaleTime) public onlyOwner {
        require(endSaleTime != 0, "Not initialized");
        require(block.timestamp < startSaleTime, "Sale already started");
        require(block.timestamp < _startSaleTime, "startSaleTime is not in future");
        require(_startSaleTime < endSaleTime, "startSaleTime >= endSaleTime");

        startSaleTime = _startSaleTime;
    }

    function setEndSaleTime(uint _endSaleTime) public onlyOwner {
        require(startSaleTime != 0, "Not initialized");
        require(block.timestamp < endSaleTime, "Sale already ended");
        require(startSaleTime < _endSaleTime, "startSaleTime >= endSaleTime");
        require(_endSaleTime < startTokensUnlock, "endSaleTime >= startTokensUnlock");

        endSaleTime = _endSaleTime;
    }

    function setStartTokensUnlock(uint _startTokensUnlock) public onlyOwner {
        require(startSaleTime != 0, "Not initialized");
        require(block.timestamp < startTokensUnlock, "Vesting already started");
        require(block.timestamp < _startTokensUnlock, "start unlock is not in future");
        require(_startTokensUnlock < endTokensUnlock, "start unlock >= end unlock");
        require(endSaleTime < _startTokensUnlock, "endSaleTime >= startTokensUnlock");

        startTokensUnlock = _startTokensUnlock;
    }

    function setEndTokensUnlock(uint _endTokensUnlock) public onlyOwner {
        require(startSaleTime != 0, "Not initialized");
        require(block.timestamp < startTokensUnlock, "Vesting already started");
        require(startTokensUnlock < _endTokensUnlock, "start unlock >= end unlock");

        endTokensUnlock = _endTokensUnlock;
    }

    /**
     * @notice Cancels the sale. Users can return all deposited funds. See {claimRefund}.
     */
    function markFailed() external onlyOwner {
        require(block.timestamp >= endSaleTime, "Not available before sale ends");
        require(block.timestamp < startTokensUnlock, "Vesting already started");
        isSaleFailed = 1;
        // withdraw unsold tokens
        token.safeTransfer(msg.sender, totalTokenAmount);
    }

    /**
     * @notice Allows a user to get back his deposit in case token sale was unsuccessful.
     */
    function claimRefund() external whenFail {
        uint amount = usersDepositRaw[msg.sender];
        usersDepositRaw[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Transfer failed");
    }

    function getTokensShare(address user) public view returns (uint) {
        if (totalDepositedWithBonus == 0) return 0;
        return (totalTokenAmount * usersDepositWithBonus[user]) / totalDepositedWithBonus;
    }

    /**
     * @notice Gets the amount of tokens currently available to claim.
     * Tokens become partially available after `startTokensUnlock` timestamp. All tokens will be
     * available to claim after `endTokensUnlock` timestamp.
     */
    function getAvailableToClaim(address user) public view returns (uint) {
        if (block.timestamp < startTokensUnlock) return 0;
        if (isSaleFailed == 1) return 0;
        return
            (getTokensShare(user) * (Math.min(block.timestamp, endTokensUnlock) - startTokensUnlock)) /
            (endTokensUnlock - startTokensUnlock) -
            alreadyClaimedTokens[user];
    }
}
