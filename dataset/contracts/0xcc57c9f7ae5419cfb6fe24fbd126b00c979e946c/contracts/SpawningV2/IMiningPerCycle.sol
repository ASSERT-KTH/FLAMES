// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMiningPerCycle {
    function cycleIndex() external view returns (uint256 index);
    function minedPerCycle(address checkAddress, uint256 cycleIndex) external view returns (uint256 mined);
}
