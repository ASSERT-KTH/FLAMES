// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Butters is ERC20, Ownable {

    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO_ADDRESS = address(0);
    address constant MARKETING_ADDRESS = 0xfdcb0c8dDbb318E756152874146c36D1EC43d13E;
    address constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant ROUTER = IUniswapV2Router02(ROUTER_ADDRESS);

    address immutable CONTRACT_ADDRESS;
    address immutable WETH_ADDRESS;
    address immutable PAIR_ADDRESS;

    constructor() payable ERC20("Butters", "BUTTRS") {
        _mint(msg.sender, 1_000_000_000 * 1e18);
        CONTRACT_ADDRESS = address(this);
        WETH_ADDRESS = ROUTER.WETH();
        PAIR_ADDRESS = IUniswapV2Factory(ROUTER.factory()).createPair(CONTRACT_ADDRESS, WETH_ADDRESS);

        isExcludedFromTaxes[msg.sender] = true;
        isExcludedFromTaxes[CONTRACT_ADDRESS] = true;
        isExcludedFromTaxes[MARKETING_ADDRESS] = true;
    }

    uint256 public buyTax = 4;
    uint256 public sellTax = 20;
    uint256 public marketingBalance;
    bool public tradingEnabled;
    mapping(address => bool) isExcludedFromTaxes;

    error Blocked();

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal pure override {
        if (amount == 0 || to == ZERO_ADDRESS || to == DEAD_ADDRESS) {
            revert Blocked();
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        bool isBuy = from == PAIR_ADDRESS;
        bool isSell = to == PAIR_ADDRESS;
        bool isTransfer = !isBuy && !isSell;
        bool isExcluded = isExcludedFromTaxes[from] || isExcludedFromTaxes[to];
        bool taxFree = isExcluded || isTransfer;

        if (!tradingEnabled) {
            if (!taxFree) {
                revert Blocked();
            }
        }

        if (!taxFree) {
            uint256 tax = isSell ? sellTax : buyTax;
            uint256 taxedTokensAmount = (amount * tax) / 100;
            amount -= taxedTokensAmount;
            marketingBalance += taxedTokensAmount;
            super._transfer(from, CONTRACT_ADDRESS, taxedTokensAmount);

            if (isSell) {
                if (marketingBalance > 0) {
                    swapTokensForReward(MARKETING_ADDRESS, marketingBalance);
                    marketingBalance = 0;
                }
            }
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForReward(address to, uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = CONTRACT_ADDRESS;
        path[1] = WETH_ADDRESS;
        _approve(CONTRACT_ADDRESS, ROUTER_ADDRESS, tokenAmount);
        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }

    function butters() external onlyOwner {
        tradingEnabled = true;
    }

    function setTaxes(uint256 buy, uint256 sell) external onlyOwner {
        buyTax = buy;
        sellTax = sell;
    }
}