// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../claim/ClaimConfigurable.sol";

// solhint-disable not-rely-on-time
/**
 * @title MoonSaleOpen
 * @notice This is a  whitelisted sale contract. Every whitelisted address
 * can buy the same amount of tokens on a FCFS basis.
 */
abstract contract MoonSaleBase is ClaimConfigurable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public maxTotal; // Max total allocated (in sale token currency)
    uint256 public total; // Total sold (in sale token currency)

    address public treasury;

    struct PaymentToken {
        IERC20 token;
        uint256 price;
    }
    PaymentToken[] public paymentTokens;

    event PaymentTokenUpdated(address token, uint256 price);
    event PaymentTokensReset();

    event Bought(
        address indexed by,
        address indexed paymentToken,
        uint256 paymentAmount,
        uint256 buyAmount
    );

    constructor(
        address _saleToken,
        uint256 _price,
        address _defaultPaymentToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _claimTime,
        uint256 _maxTotal,
        address _treasury,
        uint256[4] memory vestingData
    ) ClaimConfigurable(_claimTime, _saleToken, vestingData) {
        paymentTokens.push(PaymentToken(IERC20(_defaultPaymentToken), _price));

        startTime = _startTime;
        endTime = _endTime;

        maxTotal = _maxTotal;
        treasury = _treasury;

        // Provided by VestedClaim
        claimTime = _claimTime;
    }

    modifier withAllocation(address _address) virtual {
        require(
            getAvailableAllocation(_address) > 0,
            "No available allocation"
        );
        _;
    }

    // modify start time
    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    // modify end time
    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }

    // modify max total
    function setMaxTotal(uint256 _maxTotal) external onlyOwner {
        maxTotal = _maxTotal;
    }

    // set treasury
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    // Payment tokens
    function getPaymentTokens() public view returns (PaymentToken[] memory) {
        return paymentTokens;
    }

    function resetPaymentTokens(
        address[] calldata _tokens,
        uint256[] calldata _prices
    ) external onlyOwner {
        delete paymentTokens;
        emit PaymentTokensReset();

        for (uint256 i = 0; i < _tokens.length; i++) {
            paymentTokens.push(PaymentToken(IERC20(_tokens[i]), _prices[i]));
            emit PaymentTokenUpdated(_tokens[i], _prices[i]);
        }
    }

    function addPaymentToken(
        address _token,
        uint256 _price
    ) external onlyOwner {
        // Update existing
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            if (address(paymentTokens[i].token) == _token) {
                paymentTokens[i].price = _price;
                emit PaymentTokenUpdated(_token, _price);
                return;
            }
        }

        // Add non-existing
        paymentTokens.push(PaymentToken(IERC20(_token), _price));
        emit PaymentTokenUpdated(_token, _price);
    }

    function removePaymentToken(address _token) external onlyOwner {
        uint256 length = paymentTokens.length;
        uint256 toRemove;
        for (uint256 i = 0; i < length; i++) {
            if (address(paymentTokens[i].token) == _token) {
                toRemove = i;
            }
        }

        paymentTokens[toRemove] = paymentTokens[length - 1];
        paymentTokens.pop();
        emit PaymentTokenUpdated(_token, 0);
    }

    /**
     * @dev Get reward token price in payment token.
     * It returns "How much payment token you need to buy one sale token"
     *
     * @param paymentToken Payment token address
     *
     * @return Price in payment token
     */
    function getPriceInToken(
        address paymentToken
    ) public view returns (uint256) {
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            if (address(paymentTokens[i].token) == paymentToken) {
                return paymentTokens[i].price;
            }
        }
        return 0;
    }

    /**
     * @dev Get available sale token for an address. That's the remaining sale token allocation available.
     * @param _address Address to check
     *
     * @return Available sale token for an address
     */
    function getAvailableAllocation(
        address _address
    ) public view virtual returns (uint256) {
        return getMaxAllocation(_address) - userInfo[_address].reward;
    }

    function buy(
        address paymentToken,
        uint256 paymentAmount
    ) external withAllocation(msg.sender) whenNotPaused nonReentrant {
        require(block.timestamp >= startTime, "Not started");
        require(block.timestamp <= endTime, "Ended");

        uint256 allocationAmount = getTokenAmount(paymentToken, paymentAmount);
        require(allocationAmount > 0, "Invalid amount");

        total = total + allocationAmount;
        require(total <= maxTotal, "Max total reached");

        IERC20(paymentToken).safeTransferFrom(
            msg.sender,
            treasury,
            paymentAmount
        );

        UserInfo storage user = userInfo[msg.sender];
        uint256 totalUserAllocation = user.reward + allocationAmount;
        require(
            totalUserAllocation <= getMaxAllocation(msg.sender),
            "Address allocation limit reached"
        );
        addUserReward(msg.sender, allocationAmount);

        emit Bought(msg.sender, paymentToken, paymentAmount, allocationAmount);
    }

    /**
     * @dev Get sale token amount that you would receive for a payment token amount
     * @param paymentToken Payment token address
     * @param paymentAmount Payment token amount
     *
     * @return Sale token amount
     */
    function getTokenAmount(
        address paymentToken,
        uint256 paymentAmount
    ) public view returns (uint256) {
        if (getPriceInToken(paymentToken) == 0) return 0;
        // Sale token has 18 decimals
        return (paymentAmount * 1e18) / getPriceInToken(paymentToken);
    }

    /**
     * OVERRIDE
     */

    /**
     * @dev Get max allocation of sale token for an address. That's the maximum sale tokens an address can get.
     * @param _address Address to check
     *
     * @return Max sale token amount for an address
     */
    function getMaxAllocation(
        address _address
    ) public view virtual returns (uint256);

    function getSaleData()
        public
        view
        returns (
            address _rewardToken,
            uint256 _startTime,
            uint256 _endTime,
            uint256 _maxTotal,
            uint256 _total,
            uint256 _available,
            PaymentToken[] memory _paymentTokens
        )
    {
        return (
            address(rewardToken),
            startTime,
            endTime,
            maxTotal,
            total,
            maxTotal - total,
            paymentTokens
        );
    }

    function getUserData(
        address _address
    )
        public
        view
        returns (uint256 _allocation, uint256 _reward, uint256 _available)
    {
        return (
            getMaxAllocation(_address),
            userInfo[_address].reward,
            getAvailableAllocation(_address)
        );
    }
}
// solhint-enable not-rely-on-time
