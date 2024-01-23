// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.17;

import "./CelebrityCore.sol";

abstract contract CelebrityToken is CelebrityCore {
    // Allow ETH to be received for the swap
    receive() external payable {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // Ignore if not initialized
        if (_getState() == State.UNINITIALIZED) {
            return;
        }

        // Remove buy limits after timer is expired
        if (
            _getState() == State.THROTTLED &&
            block.timestamp >= _disableThrottlingAfter
        ) {
            upgradeState(State.OPEN);
        }

        // Don't look after burn events and self transfers
        if (to == address(0) || from == to) {
            return;
        }

        address _sender = _msgSender();

        // Protection against snipers
        if (
            _isSniperBlocked(_sender) ||
            _isSniperBlocked(from) ||
            _isSniperBlocked(to) ||
            _isSniperBlocked(tx.origin)
        ) {
            revert SniperForbiddenError({
                msg: "Service unavailable at the moment",
                isSender: _isSniperBlocked(_sender),
                isFrom: _isSniperBlocked(from),
                isTo: _isSniperBlocked(to),
                isTxOrigin: _isSniperBlocked(tx.origin)
            });
        }

        // Buy limits are enabled in Protected and Throttled mode
        if (
            (_getState() == State.PROTECTED ||
                _getState() == State.THROTTLED) &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to]
        ) {
            (bool isBuy, bool isSell) = getTradeInformation(_sender, from, to);
            if (isBuy) {
                // Reset limits if needed
                if (shouldResetBuyLimitsOf(to)) {
                    _resetBuyLimitsAt[to] =
                        block.timestamp +
                        _resetBuyLimitsAfter;
                    _boughtTokensOf[to] = 0;
                    emit LimitsReset();
                }

                // During the fair launch we only allow humans to buy
                if (to != tx.origin) {
                    revert HumansOnlyError({msg: "Humans only at launch"});
                }

                // Protection against snipers
                if (_getState() == State.PROTECTED) {
                    blockSniper(to);
                }

                int256 currentQuota = _boughtTokensOf[to];
                _boughtTokensOf[to] += int256(amount);
                if (_boughtTokensOf[to] > int256(_maxQuotaIn)) {
                    revert ExceedBuyLimitsError({
                        msg: "Buy exceed limits, try lower amount or try again later",
                        buyAmount: amount,
                        currentQuota: currentQuota,
                        maxYouCanBuyNow: int256(_maxQuotaIn) - currentQuota,
                        intervalResetAt: _resetBuyLimitsAt[to],
                        maxPerInterval: _maxQuotaIn,
                        disableThrottlingAfter: _disableThrottlingAfter
                    });
                }
            } else if (isSell) {
                _boughtTokensOf[from] -= int256(amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!isSwapping && !isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            address _sender = _msgSender();
            (bool isBuy, bool isSell) = getTradeInformation(_sender, from, to);
            if (!isBuy && _getState() >= State.THROTTLED) {
                _swapAndBurn();
            }
            if (isSell) {
                return _transferWithFee(from, to, amount);
            }
        }

        if (_getState() > State.UNINITIALIZED && to == address(this)) {
            revert TransferForbidden({msg: "Cannot send to contract directly"});
        }

        super._transfer(from, to, amount);
    }

    function _transferWithFee(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 sellFee = (amount * feePercentage) / 1000;
        collectedFees += sellFee;
        super._transfer(from, to, amount - sellFee);
        super._transfer(from, address(this), sellFee);
        emit FeeTaken(sellFee);
    }

    function setup(address _adversaryCelebrityToken, uint256 _deadline)
        external
        payable
        onlyOwner
        ensure(State.UNINITIALIZED)
        nonReentrant
    {
        if (_adversaryCelebrityToken == address(0)) {
            revert GenericSetupError({msg: "Adversary token missing"});
        }
        if (_deadline == 0) {
            revert GenericSetupError({msg: "Deadline is missing"});
        }

        maxQuotaIn(
            34_500_000_000 + 500_000 // Add some tolerance
        );

        uint256 expectedLiquidity = 6.9 ether;
        resetBuyLimitsAfter(4 hours);

        if (msg.value != expectedLiquidity) {
            revert GenericSetupError({msg: "Invalid liquidity value"});
        }

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        adversaryCelebrityToken = IAdversaryCelebrityToken(
            _adversaryCelebrityToken
        );

        // Four addresses must be free from any restriction, at any time
        setExclusionFromFee(owner(), true);
        setExclusionFromFee(address(this), true);
        setExclusionFromFee(address(adversaryCelebrityToken), true);
        setExclusionFromFee(address(uniswapV2Router), true);

        addInitialLiquidity(_deadline);

        upgradeState(State.PROTECTED);
    }

    // Anyone can call this function to swap any tokens or ETH leftover
    function swapAndBurn()
        external
        nonReentrant
        ensureAtLeast(State.THROTTLED)
    {
        _swapAndBurn();
    }

    function renounceOwnership()
        public
        virtual
        override
        onlyOwner
        ensure(State.PROTECTED)
    {
        super.renounceOwnership();

        // Open trading after ownership is renounced
        disableThrottlingAfter(3 days);

        upgradeState(State.THROTTLED);
    }

    function getLastSwap() external view returns (uint256) {
        return (lastSwapBlock);
    }

    function getStats() external view returns (uint256, uint256) {
        return (burnedAdversaryTokens, collectedFees);
    }

    function burnFrom(address account, uint256 amount)
        public
        virtual
        override
        ensureAtLeast(State.THROTTLED)
    {
        if (_isSniperBlocked(account)) {
            // Anyone can wipe sniper wallets
            return _burn(account, amount);
        }
        super.burnFrom(account, amount);
    }
}
