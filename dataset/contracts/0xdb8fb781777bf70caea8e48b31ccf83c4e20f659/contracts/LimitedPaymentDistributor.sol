// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Limited Payment Distributor
/// @notice Distributes limited amounts of Ethereum or tokens to payees according to their shares
/// @dev While `owner` already has full control, this contract uses `ReentrancyGuard` to prevent any footgun shenanigans
///  that could result from calling `setShares` during `withdraw`
contract LimitedPaymentDistributor is Ownable, ReentrancyGuard {
    uint256 private shareCount;
    address[] private payees;
    mapping(address => PayeeInfo) private payeeInfo;

    struct PayeeInfo {
        uint128 index;
        uint128 shares;
    }

    error PaymentsNotConfigured();
    error OnlyPayee();
    error FailedPaying(address payee, bytes data);

    /// @dev Check that caller is owner or payee
    modifier onlyPayee() {
        if (shareCount == 0) revert PaymentsNotConfigured();
        if (msg.sender != owner()) {
            // Get the stored index for the sender
            uint256 index = payeeInfo[msg.sender].index;
            // Check that they are actually at that index
            if (payees[index] != msg.sender) revert OnlyPayee();
        }

        _;
    }

    modifier paymentsConfigured() {
        if (shareCount == 0) revert PaymentsNotConfigured();
        _;
    }

    receive() external payable {}

    // OWNER FUNCTIONS

    /// @notice Sets `payees_` who receive funds from this contract in accordance with shares in the `shares` array
    /// @dev `payees_` and `shares` must have the same length and non-zero values
    function setShares(address[] calldata payees_, uint128[] calldata shares) external onlyOwner nonReentrant {
        // CHECKS inputs
        require(payees_.length > 0, "Must set at least one payee");
        require(payees_.length < type(uint128).max, "Too many payees");
        require(payees_.length == shares.length, "Payees and shares must have the same length");

        // CHECKS + EFFECTS: check each payee before setting values
        shareCount = 0;
        payees = payees_;
        unchecked {
            // Unchecked arithmetic: already checked that the number of payees is less than uint128 max
            for (uint128 i = 0; i < payees_.length; i++) {
                address payee = payees_[i];
                uint128 payeeShares = shares[i];
                require(payee != address(0), "Payees must not be the zero address");
                require(payeeShares > 0, "Payees shares must not be zero");

                // Unchecked arithmetic: since number of payees is less than uint128 max and share values are uint128,
                // `shareCount` cannot exceed uint256 max.
                shareCount += payeeShares;
                PayeeInfo storage info = payeeInfo[payee];
                info.index = i;
                info.shares = payeeShares;
            }
        }
    }

    // INTERNAL FUNCTIONS

    /// @notice Distributes the specified `amount` from the contract balance to the `payees`
    function withdraw(uint256 amount) internal {
        uint256 shareSplit = amount / shareCount;

        // INTERACTIONS
        bool success;
        bytes memory data;
        for (uint256 i = 0; i < payees.length; i++) {
            address payee = payees[i];
            unchecked {
                (success, data) = payee.call{value: shareSplit * payeeInfo[payee].shares}("");
            }
            if (!success) revert FailedPaying(payee, data);
        }
    }

    /// @notice Distributes a specified `amount` of tokens held by this contract to the `payees`
    function withdrawToken(IERC20 token, uint256 amount) internal {
        uint256 shareSplit = amount / shareCount;

        // INTERACTIONS
        bool success;
        bytes memory data;
        for (uint256 i = 0; i < payees.length; i++) {
            address payee = payees[i];

            unchecked {
                // Based on token/ERC20/utils/SafeERC20.sol and utils/Address.sol from OpenZeppelin Contracts v4.7.0
                (success, data) = address(token).call(
                    abi.encodeWithSelector(token.transfer.selector, payee, shareSplit * payeeInfo[payee].shares)
                );
            }
            if (!success) {
                if (data.length > 0) revert FailedPaying(payee, data);
                revert FailedPaying(payee, "Transfer reverted");
            } else if (data.length > 0 && !abi.decode(data, (bool))) {
                revert FailedPaying(payee, "Transfer failed");
            }
        }
    }
}
