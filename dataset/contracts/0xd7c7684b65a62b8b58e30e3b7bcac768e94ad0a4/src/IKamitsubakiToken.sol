// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IKamitsubakiToken {
    function mint(address to, uint256 _mintAmount) external payable;
}
