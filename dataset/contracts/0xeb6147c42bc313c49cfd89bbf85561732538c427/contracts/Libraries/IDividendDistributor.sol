// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDividendDistributor {
    function claimDividend(address shareholder) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function unstuckToken(address _receiver) external;
}