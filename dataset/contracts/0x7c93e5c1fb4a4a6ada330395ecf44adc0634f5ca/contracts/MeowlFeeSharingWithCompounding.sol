// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IRewardsDistribution} from "./interfaces/IRewardsDistribution.sol";

/**
 * @title MeowlFeeSharingWithCompounding
 * @notice It sells WETH to MEOWL using Uniswap V2.
 * @dev Prime shares represent the number of shares in the FeeSharingSystem. When not specified, shares represent secondary shares in this contract.
 */
contract MeowlFeeSharingWithCompounding is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Maximum buffer between 2 harvests (in blocks)
    uint256 public constant MAXIMUM_HARVEST_BUFFER_BLOCKS = 6500;

    // FeeSharingSystem (handles the distribution of WETH for MEOWL stakers)
    IRewardsDistribution public immutable feeSharingSystem;

    // Router of Uniswap v2
    IUniswapV2Router02 public immutable uniswapRouter;

    // Minimum deposit in MEOWL (it is derived from the FeeSharingSystem)
    uint256 public immutable MINIMUM_DEPOSIT_MEOWL;

    // Meowl Token (MEOWL)
    IERC20 public immutable meowl;

    // Reward token (WETH)
    IERC20 public immutable rewardToken;

    // Whether harvest and WETH selling is triggered automatically at user action
    bool public canHarvest;

    // Buffer between two harvests (in blocks)
    uint256 public harvestBufferBlocks;

    // Last user action block
    uint256 public lastHarvestBlock;

    // Maximum price of MEOWL (in WETH) multiplied 1e18 (e.g., 0.0004 ETH --> 4e14)
    uint256 public maxPriceMEOWLInWETH;

    // Threshold amount (in rewardToken)
    uint256 public thresholdAmount;

    // Total number of shares outstanding
    uint256 public totalShares;

    // Keeps track of number of user shares
    mapping(address => uint256) public userInfo;

    event ConversionToMEOWL(uint256 amountSold, uint256 amountReceived);
    event Deposit(address indexed user, uint256 amount);
    event FailedConversion();
    event HarvestStart();
    event HarvestStop();
    event NewHarvestBufferBlocks(uint256 harvestBufferBlocks);
    event NewMaximumPriceMEOWLInWETH(uint256 maxPriceMEOWLInWETH);
    event NewThresholdAmount(uint256 thresholdAmount);
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @notice Constructor
     * @param _feeSharingSystem address of the fee sharing system contract
     * @param _uniswapRouter address of the Uniswap v2 router
     */
    constructor(address _feeSharingSystem, address _uniswapRouter) {
        address meowlTokenAddress = address(
            IRewardsDistribution(_feeSharingSystem).stakingToken()
        );
        address rewardTokenAddress = address(
            IRewardsDistribution(_feeSharingSystem).rewardsToken()
        );

        meowl = IERC20(meowlTokenAddress);
        rewardToken = IERC20(rewardTokenAddress);

        feeSharingSystem = IRewardsDistribution(_feeSharingSystem);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);

        IERC20(meowlTokenAddress).approve(_feeSharingSystem, type(uint256).max);
        IERC20(rewardTokenAddress).approve(_uniswapRouter, type(uint256).max);

        MINIMUM_DEPOSIT_MEOWL = 10 ** 18;
    }

    /**
     * @notice Deposit MEOWL tokens
     * @param amount amount to deposit (in MEOWL)
     * @dev There is a limit of 1 MEOWL per deposit to prevent potential manipulation of the shares
     */
    function deposit(uint256 amount) external nonReentrant whenNotPaused {
        require(
            amount >= MINIMUM_DEPOSIT_MEOWL,
            "Deposit: Amount must be >= 1 MEOWL"
        );

        if (
            block.number > (lastHarvestBlock + harvestBufferBlocks) &&
            canHarvest &&
            totalShares != 0
        ) {
            _harvestAndSellAndCompound();
        }

        // Transfer MEOWL tokens to this address
        meowl.safeTransferFrom(msg.sender, address(this), amount);

        // Fetch the total number of MEOWL staked by this contract
        uint256 totalAmountStaked = feeSharingSystem.balanceOf(address(this));

        uint256 currentShares = totalShares == 0
            ? amount
            : (amount * totalShares) / totalAmountStaked;
        require(currentShares != 0, "Deposit: Fail");

        // Adjust number of shares for user/total
        userInfo[msg.sender] += currentShares;
        totalShares += currentShares;

        // Deposit to FeeSharingSystem contract
        feeSharingSystem.stake(amount);

        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Redeem shares for MEOWL tokens
     * @param shares number of shares to redeem
     */
    function withdraw(uint256 shares) external nonReentrant {
        require(
            (shares > 0) && (shares <= userInfo[msg.sender]),
            "Withdraw: Shares equal to 0 or larger than user shares"
        );

        _withdraw(shares);
    }

    /**
     * @notice Withdraw all shares of sender
     */
    function withdrawAll() external nonReentrant {
        require(userInfo[msg.sender] > 0, "Withdraw: Shares equal to 0");

        _withdraw(userInfo[msg.sender]);
    }

    /**
     * @notice Harvest pending WETH, sell them to MEOWL, and deposit MEOWL (if possible)
     * @dev Only callable by owner.
     */
    function harvestAndSellAndCompound() external nonReentrant onlyOwner {
        require(totalShares != 0, "Harvest: No share");
        require(block.number != lastHarvestBlock, "Harvest: Already done");

        _harvestAndSellAndCompound();
    }

    /**
     * @notice Adjust allowance if necessary
     * @dev Only callable by owner.
     */
    function checkAndAdjustMEOWLTokenAllowanceIfRequired() external onlyOwner {
        meowl.approve(address(feeSharingSystem), type(uint256).max);
    }

    /**
     * @notice Adjust allowance if necessary
     * @dev Only callable by owner.
     */
    function checkAndAdjustRewardTokenAllowanceIfRequired() external onlyOwner {
        rewardToken.approve(address(uniswapRouter), type(uint256).max);
    }

    /**
     * @notice Update harvest buffer block
     * @param _newHarvestBufferBlocks buffer in blocks between two harvest operations
     * @dev Only callable by owner.
     */
    function updateHarvestBufferBlocks(
        uint256 _newHarvestBufferBlocks
    ) external onlyOwner {
        require(
            _newHarvestBufferBlocks <= MAXIMUM_HARVEST_BUFFER_BLOCKS,
            "Owner: Must be below MAXIMUM_HARVEST_BUFFER_BLOCKS"
        );
        harvestBufferBlocks = _newHarvestBufferBlocks;

        emit NewHarvestBufferBlocks(_newHarvestBufferBlocks);
    }

    /**
     * @notice Start automatic harvest/selling transactions
     * @dev Only callable by owner
     */
    function startHarvest() external onlyOwner {
        canHarvest = true;

        emit HarvestStart();
    }

    /**
     * @notice Stop automatic harvest transactions
     * @dev Only callable by owner
     */
    function stopHarvest() external onlyOwner {
        canHarvest = false;

        emit HarvestStop();
    }

    /**
     * @notice Update maximum price of MEOWL in WETH
     * @param _newMaxPriceMEOWLInWETH new maximum price of MEOWL in WETH times 1e18
     * @dev Only callable by owner
     */
    function updateMaxPriceOfMEOWInWETH(
        uint256 _newMaxPriceMEOWLInWETH
    ) external onlyOwner {
        maxPriceMEOWLInWETH = _newMaxPriceMEOWLInWETH;

        emit NewMaximumPriceMEOWLInWETH(_newMaxPriceMEOWLInWETH);
    }

    /**
     * @notice Adjust threshold amount for periodic Uniswap v3 WETH --> MEOWL conversion
     * @param _newThresholdAmount new threshold amount (in WETH)
     * @dev Only callable by owner
     */
    function updateThresholdAmount(
        uint256 _newThresholdAmount
    ) external onlyOwner {
        thresholdAmount = _newThresholdAmount;

        emit NewThresholdAmount(_newThresholdAmount);
    }

    /**
     * @notice Pause
     * @dev Only callable by owner
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpause
     * @dev Only callable by owner
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Calculate price of one share (in MEOWL token)
     * Share price is expressed times 1e18
     */
    function calculateSharePriceInMEOWL() external view returns (uint256) {
        uint256 totalAmountStakedWithAggregator = feeSharingSystem.balanceOf(
            address(this)
        );

        return
            totalShares == 0
                ? MINIMUM_DEPOSIT_MEOWL
                : (totalAmountStakedWithAggregator * MINIMUM_DEPOSIT_MEOWL) /
                    (totalShares);
    }

    /**
     * @notice Calculate price of one share (in prime share)
     * Share price is expressed times 1e18
     */
    function calculateSharePriceInPrimeShare() external view returns (uint256) {
        uint256 totalNumberPrimeShares = feeSharingSystem.balanceOf(
            address(this)
        );

        return
            totalShares == 0
                ? MINIMUM_DEPOSIT_MEOWL
                : (totalNumberPrimeShares * MINIMUM_DEPOSIT_MEOWL) /
                    totalShares;
    }

    /**
     * @notice Calculate shares value of a user (in MEOWL)
     * @param user address of the user
     */
    function calculateSharesValueInMEOWL(
        address user
    ) external view returns (uint256) {
        uint256 totalAmountStakedWithAggregator = feeSharingSystem.balanceOf(
            address(this)
        );

        return
            totalShares == 0
                ? 0
                : (totalAmountStakedWithAggregator * userInfo[user]) /
                    totalShares;
    }

    /**
     * @notice Harvest pending WETH, sell them to MEOWL, and deposit MEOWL (if possible)
     */
    function _harvestAndSellAndCompound() internal {
        // Try/catch to prevent revertions if nothing to harvest
        try feeSharingSystem.getReward() {} catch {}

        uint256 amountToSell = rewardToken.balanceOf(address(this));

        if (amountToSell >= thresholdAmount) {
            bool isExecuted = _sellRewardTokenToMEOWL(amountToSell);

            if (isExecuted) {
                uint256 adjustedAmount = meowl.balanceOf(address(this));

                if (adjustedAmount >= MINIMUM_DEPOSIT_MEOWL) {
                    feeSharingSystem.stake(adjustedAmount);
                }
            }
        }

        // Adjust last harvest block
        lastHarvestBlock = block.number;
    }

    /**
     * @notice Sell WETH to MEOWL
     * @param _amount amount of rewardToken to convert (WETH)
     * @return whether the transaction went through
     */
    function _sellRewardTokenToMEOWL(uint256 _amount) internal returns (bool) {
        uint256 amountOutMinimum = maxPriceMEOWLInWETH != 0
            ? (_amount * 1e18) / maxPriceMEOWLInWETH
            : 0;

        address[] memory path = new address[](2);
        path[0] = address(rewardToken);
        path[1] = address(meowl);

        uint startBal = meowl.balanceOf(address(this));
        // Swap
        try
            uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                amountOutMinimum,
                path,
                address(this),
                block.timestamp
            )
        {
            uint amountOut = meowl.balanceOf(address(this)) - startBal;
            emit ConversionToMEOWL(_amount, amountOut);
            return true;
        } catch {
            emit FailedConversion();
            return false;
        }
    }

    /**
     * @notice Withdraw shares
     * @param _shares number of shares to redeem
     * @dev The difference between the two snapshots of MEOWL balances is used to know how many tokens to transfer to user.
     */
    function _withdraw(uint256 _shares) internal {
        if (
            block.number > (lastHarvestBlock + harvestBufferBlocks) &&
            canHarvest
        ) {
            _harvestAndSellAndCompound();
        }

        // Take snapshot of current MEOWL balance
        uint256 previousBalanceMEOWL = meowl.balanceOf(address(this));

        // Fetch total number of prime shares
        uint256 totalNumberPrimeShares = feeSharingSystem.balanceOf(
            address(this)
        );

        // Calculate number of prime shares to redeem based on existing shares (from this contract)
        uint256 currentNumberPrimeShares = (totalNumberPrimeShares * _shares) /
            totalShares;

        // Adjust number of shares for user/total
        userInfo[msg.sender] -= _shares;
        totalShares -= _shares;

        // Withdraw amount equivalent in prime shares
        feeSharingSystem.withdraw(currentNumberPrimeShares);

        // Calculate the difference between the current balance of MEOWL with the previous snapshot
        uint256 amountToTransfer = meowl.balanceOf(address(this)) -
            previousBalanceMEOWL;

        // Transfer the MEOWL amount back to user
        meowl.safeTransfer(msg.sender, amountToTransfer);

        emit Withdraw(msg.sender, amountToTransfer);
    }
}
