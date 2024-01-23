// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IUniswapPairOracle {
    function getAssetPrice(address token) external view returns (uint amountOut);
}
