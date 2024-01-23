// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IUniswapPairOracle.sol";
import "./IAggregatorV3Interface.sol";

contract LBRPriceOFeed {
    IUniswapPairOracle public immutable pairOracle;
    address public immutable LBR;
     IAggregatorV3Interface public priceFeed;
      //priceFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419

    constructor(address _pairOracle, address _LBR, address _etherOracle) public {
        pairOracle = IUniswapPairOracle(_pairOracle);
        LBR = _LBR;
        priceFeed = IAggregatorV3Interface(_etherOracle);

    }
 
    function latestRoundData() external view returns(uint80, int, uint, uint, uint80) {
        uint256 price = pairOracle.getAssetPrice(LBR);
        ( ,int256 ethPrice, , , ) = priceFeed.latestRoundData();
        uint256 lbrPrice = price * uint256(ethPrice) / 1e18;
        return (0, int(lbrPrice), 0,0,0);
    }
}