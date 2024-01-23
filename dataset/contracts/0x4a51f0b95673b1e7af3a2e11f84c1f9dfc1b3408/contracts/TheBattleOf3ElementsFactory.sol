// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

//import "hardhat/console.sol";

import "contracts/nft/IMintableNft.sol";
import "contracts/lib/Ownable.sol";
import "contracts/INftController.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

contract TheBattleOf3ElementsFactory is Ownable {
    using PRBMathUD60x18 for uint256;

    event OnBuy(address indexed account, uint256 count, uint256 price);

    // nft
    INftController public immutable nftController;
    IMintableNft public immutable fire;
    IMintableNft public immutable ice;
    IMintableNft public immutable water;
    // price data
    uint256 public lastPrice = 1e16;
    uint256 constant e1 = 1000200000000000000;
    uint256 constant e2 = 1000700000000000000;
    uint256 constant d = 34822e18;
    uint256 public _maxMintCount = 10;
    uint256 public constant addMintCount = 5;
    uint256 public constant addMintCountTimerMinutes = 1;
    // ethereum endpoints
    address public feeAddress;
    address public poolAddress;
    uint256 public constant feeAddressPercent = 80;

    constructor(
        address nftController_,
        address fire_,
        address ice_,
        address water_
    ) {
        nftController = INftController(nftController_);
        fire = IMintableNft(fire_);
        ice = IMintableNft(ice_);
        water = IMintableNft(water_);
        feeAddress = msg.sender;
        poolAddress = feeAddress;
    }

    function setFeeAddress(address addr) external onlyOwner {
        feeAddress = addr;
    }

    function setPoolAddress(address addr) external onlyOwner {
        poolAddress = addr;
    }

    function mint(address to, uint256 count) external payable {
        require(nftController.gameStarted(), "the game is not started (yet)");

        uint256 i1 = (block.timestamp + nftController.mintedCount()) %
            (count + 1);
        uint256 i2 = (block.timestamp +
            nftController.mintedCount() +
            count +
            block.number) % (count + 1);
        if (i1 > i2) {
            uint256 b = i1;
            i1 = i2;
            i2 = b;
        }

        uint256 c1 = i1;
        uint256 c2 = i2 - i1;
        uint256 c3 = count - i2;

        uint256 ethConsumed;

        ethConsumed += _mintTo(to, c1, fire);
        ethConsumed += _mintTo(to, c2, ice);
        ethConsumed += _mintTo(to, c3, water);

        // check eth value
        require(ethConsumed <= msg.value, "not enough eth");

        // eth calculations
        uint256 ethSurplus = msg.value - ethConsumed;
        uint256 fee = (feeAddressPercent * ethConsumed) / 100;
        uint256 pooled = ethConsumed - fee;

        // send eth to endpoints
        sendEth(msg.sender, ethSurplus);
        sendEth(feeAddress, fee);
        sendEth(poolAddress, pooled);

        emit OnBuy(to, count, ethConsumed);
    }

    function _mintTo(
        address to,
        uint256 count,
        IMintableNft nft
    ) internal returns (uint256) {
        if (count == 0) return 0;
        // mint
        uint256 ethConsumed;
        for (uint256 i = 0; i < count; ++i) ethConsumed += _mint(to, nft);
        return ethConsumed;
    }

    function _mint(address to, IMintableNft nft) internal returns (uint256) {
        uint256 balance = fire.balanceOf(to) +
            ice.balanceOf(to) +
            water.balanceOf(to);
        require(balance < this.maxMintCount(), "maximum nft count per account limit");
        lastPrice = this.getPrice(1);
        //console.log("p[", nft.mintedCount() + 1, "]=", lastPrice);
        nft.mint(to, lastPrice);
        nftController.addMintedCount(1);
        return lastPrice;
    }

    function sendEth(address addr, uint256 ethCount) internal {
        if (ethCount <= 0) return;
        (bool sent, ) = addr.call{value: ethCount}("");
        require(sent, "ethereum is not sent");
    }

    function getPrice(uint256 count) external view returns (uint256 price) {
        uint256 sum;
        uint256 curPrice = lastPrice;
        uint256 mintNumber = nftController.mintedCount() + 1;
        for (uint256 i = 0; i < count; ++i) {
            uint256 k = e2.pow(mintNumber * 1e18 - 1e18) - 1e18;
            curPrice += ((e1.pow(mintNumber * k) - 1e18) * k) / d;
            sum += curPrice;
            ++mintNumber;
        }
        return sum;
    }

    function maxMintCount() external view returns (uint256) {
        if (
            block.timestamp <= nftController.startGameTime() ||
            nftController.startGameTime() == 0
        ) return _maxMintCount;

        uint256 intervals = (block.timestamp - nftController.startGameTime()) /
            (addMintCountTimerMinutes * 1 minutes);
        return _maxMintCount + addMintCount * intervals;
    }
}
