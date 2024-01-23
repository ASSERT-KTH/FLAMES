// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.17;

import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IAdversaryCelebrityToken.sol";
import "./StatefulContract.sol";

error SniperForbiddenError(
    string msg,
    bool isSender,
    bool isFrom,
    bool isTo,
    bool isTxOrigin
);
error ExceedBuyLimitsError(
    string msg,
    uint256 buyAmount,
    int256 currentQuota,
    int256 maxYouCanBuyNow,
    uint256 intervalResetAt,
    uint256 maxPerInterval,
    uint256 disableThrottlingAfter
);
error HumansOnlyError(string msg);
error GenericSetupError(string msg);
error TransferForbidden(string msg);
error NotAdversaryToken(string msg);

abstract contract CelebrityCore is
    ERC20,
    ERC20Burnable,
    ReentrancyGuard,
    Ownable,
    StatefulContract
{
    event LimitsReset();
    event FailedToSwapToAdversary(uint256 amount);
    event FailedToSwapToETH(uint256 amount);
    event FeeTaken(uint256 amount);
    event BurnedAdversaryTokens(uint256 amount);

    uint8 internal constant feePercentage = 69;
    uint256 private immutable fixedTotalSupply =
        formatTokens(6_900_000_000_000);

    IUniswapV2Router02 internal constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private immutable WETH9 = uniswapV2Router.WETH();

    address internal uniswapV2Pair;
    IAdversaryCelebrityToken internal adversaryCelebrityToken;

    mapping(address => bool) internal isExcludedFromFee;

    bool internal isSwapping = false;
    uint256 internal burnedAdversaryTokens = 0;
    uint256 internal collectedFees = 0;
    uint256 internal lastSwapBlock = 0;

    mapping(address => uint256) internal _resetBuyLimitsAt;
    mapping(address => int256) internal _boughtTokensOf;

    uint256 internal _resetBuyLimitsAfter;
    uint256 internal _maxQuotaIn;
    uint256 internal _disableThrottlingAfter;

    // Anti-bot protection (switched off when ownership is renounced)
    mapping(address => bool) private _0017333;

    modifier swapLock() {
        isSwapping = true;
        _;
        isSwapping = false;
        lastSwapBlock = block.number;
    }

    constructor() {
        _mint(address(this), fixedTotalSupply);
    }

    function shouldResetBuyLimitsOf(address account)
        internal
        view
        returns (bool)
    {
        return block.timestamp >= _resetBuyLimitsAt[account];
    }

    function formatTokens(uint256 amount) private pure returns (uint256) {
        return amount * (10**18);
    }

    // This check is compatible with all Uniswap-like AMM
    function hasFactory(address _sender) private view returns (bool) {
        if (Address.isContract(_sender)) {
            IUniswapV2Router02 _router = IUniswapV2Router02(_sender);
            try _router.factory() returns (address factory) {
                if (factory != address(0)) {
                    return true;
                }
            } catch {}
        }
        return false;
    }

    function getTradeInformation(
        address _sender,
        address from,
        address to
    ) internal view returns (bool isBuy, bool isSell) {
        if (!hasFactory(_sender)) {
            return (false, false);
        }
        return (hasFactory(from), hasFactory(to));
    }

    function setExclusionFromFee(address account, bool _isExcludedFromFee)
        internal
    {
        isExcludedFromFee[account] = _isExcludedFromFee;
    }

    function _isSniperBlocked(address account) internal view returns (bool) {
        return _0017333[account];
    }

    function blockSniper(address account) internal {
        if (isExcludedFromFee[account]) {
            return;
        }
        _0017333[account] = true;
    }

    function resetBuyLimitsAfter(uint256 value) internal {
        _resetBuyLimitsAfter = value;
    }

    function maxQuotaIn(uint256 value) internal {
        _maxQuotaIn = formatTokens(value);
    }

    function disableThrottlingAfter(uint256 value) internal {
        _disableThrottlingAfter = block.timestamp + value;
    }

    function addInitialLiquidity(uint256 deadline)
        internal
        ensure(State.UNINITIALIZED)
        onlyOwner
    {
        _approve(address(this), address(uniswapV2Router), fixedTotalSupply);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            fixedTotalSupply,
            fixedTotalSupply,
            msg.value,
            owner(),
            deadline
        );
    }

    function _swapAndBurn() internal swapLock {
        if (lastSwapBlock != block.number) {
            if (adversaryCelebrityToken.getLastSwap() != block.number) {
                uint256 selfBalance = balanceOf(address(this));
                if (selfBalance > 0) {
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = WETH9;
                    _approve(
                        address(this),
                        address(uniswapV2Router),
                        selfBalance
                    );
                    try
                        uniswapV2Router
                            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                                selfBalance,
                                0,
                                path,
                                address(this),
                                block.timestamp
                            )
                    {} catch {
                        emit FailedToSwapToETH(selfBalance);
                    }
                }
            }

            uint256 ethBalance = address(this).balance;
            if (ethBalance > 0) {
                address[] memory path = new address[](2);
                path[0] = WETH9;
                path[1] = address(adversaryCelebrityToken);
                try
                    uniswapV2Router
                        .swapExactETHForTokensSupportingFeeOnTransferTokens{
                        value: ethBalance
                    }(0, path, address(this), block.timestamp)
                {} catch {
                    emit FailedToSwapToAdversary(ethBalance);
                }
            }

            uint256 adversaryBalance = adversaryCelebrityToken.balanceOf(
                address(this)
            );
            if (adversaryBalance > 0) {
                adversaryCelebrityToken.burn(adversaryBalance);
                burnedAdversaryTokens += adversaryBalance;
                emit BurnedAdversaryTokens(adversaryBalance);
            }
        }
    }
}
