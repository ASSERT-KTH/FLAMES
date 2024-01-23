// SPDX-License-Identifier: MIT
// Copyright (c) 2022 - 2023 Fellowship

pragma solidity ^0.8.7;
import "./Pausable.sol";

contract TimedSale is Pausable {
    /// @notice Timestamp when this auction starts allowing minting
    uint256 public startTime;

    uint256 private pauseStart;
    uint256 internal pastPauseDelay;

    /// @notice An error returned when the auction has already started
    error AlreadyStarted();
    /// @notice An error returned when the auction has not yet started
    error NotYetStarted();

    constructor(uint startTime_) {
        // CHECKS inputs
        require(startTime_ >= block.timestamp, "Start time cannot be in the past");

        // EFFECTS
        startTime = startTime_;
    }

    modifier started() {
        if (!isStarted()) revert NotYetStarted();
        _;
    }
    modifier unstarted() {
        if (isStarted()) revert AlreadyStarted();
        _;
    }

    // OWNER FUNCTIONS

    /// @notice Pause this contract
    /// @dev Can only be called by the contract `owner`
    function pause() public override {
        // CHECKS + EFFECTS: `Pausable` handles checking permissions and setting pause state
        super.pause();
        // More EFFECTS
        pauseStart = block.timestamp;
    }

    /// @notice Resume this contract
    /// @dev Can only be called by the contract `owner`. Pricing tiers will pick up where they left off.
    function unpause() public override {
        // CHECKS + EFFECTS: `Pausable` handles checking permissions and setting pause state
        super.unpause();
        // More EFFECTS
        if (block.timestamp <= startTime) {
            return;
        }
        // Find the amount time the auction should have been live, but was paused
        unchecked {
            // Unchecked arithmetic: computed value will be < block.timestamp and >= 0
            if (pauseStart < startTime) {
                pastPauseDelay = block.timestamp - startTime;
            } else {
                pastPauseDelay += (block.timestamp - pauseStart);
            }
        }
    }

    /// @notice Update the auction start time
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function setStartTime(uint256 startTime_) external unstarted onlyOwner {
        // CHECKS inputs
        require(startTime_ >= block.timestamp, "New start time cannot be in the past");
        // EFFECTS
        startTime = startTime_;
    }

    // INTERNAL FUNCTIONS

    function isStarted() internal view virtual returns (bool) {
        return (isPaused ? pauseStart : block.timestamp) >= startTime;
    }

    function timeElapsed() internal view returns (uint256) {
        if (!isStarted()) return 0;
        unchecked {
            // pastPauseDelay cannot be greater than the time passed since startTime
            if (!isPaused) {
                return block.timestamp - startTime - pastPauseDelay;
            }

            // pastPauseDelay cannot be greater than the time between startTime and pauseStart
            return pauseStart - startTime - pastPauseDelay;
        }
    }
}
