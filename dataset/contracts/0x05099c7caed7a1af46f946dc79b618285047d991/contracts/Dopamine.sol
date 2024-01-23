// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

//////////////////////////////////////////////////////
//     ___                            _
//    /   \___  _ __   __ _ _ __ ___ (_)_ __   ___
//   / /\ / _ \| '_ \ / _` | '_ ` _ \| | '_ \ / _ \
//  / /_// (_) | |_) | (_| | | | | | | | | | |  __/
// /___,' \___/| .__/ \__,_|_| |_| |_|_|_| |_|\___|
//             |_|
//////////////////////////////////////////////////////
//https://dopamine.today/
//https://t.me/DopamineTelegram
//////////////////////////////////////////////////////
//
// plain vanilla erc20
// designed to be launched on Uniswapv2
// - maxWallet
// - no tax
// - no transferdelay
// - no blacklist
// the pair is set via setAMM
//////////////////////////////////////////////////////
// By the power vested in me by nobody in particular
// Dopamine is hereby released
//////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dopamine is ERC20, Ownable {
    address public constant uniswapRouterAddress =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // 1% from total supply maxTransactionAmountTxn;
    uint256 public immutable maxTransactionAmount = 10_000_000 * 1e18;
    // 1% from total supply maxWallet;
    uint256 public immutable maxWallet = 10_000_000 * 1e18;

    //state bools
    bool public limitsActive = true;
    bool public tradingActive = false;

    // exlcude from max transaction amount
    mapping(address => bool) public isExcluded;

    // store addresses that a automatic market maker pairs.
    mapping(address => bool) public automatedMarketMakerPairs;

    mapping(address => uint256) public holderFirstTransferTimestamp;

    constructor() payable ERC20("Dopamine", "XDOPA") {
        uint256 totalSupply = 1_000_000_000 * 1e18;
        excludeFrom(owner(), true);
        excludeFrom(address(this), true);
        excludeFrom(address(0xdead), true);
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function startTrading() external onlyOwner {
        tradingActive = true;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsActive = false;
    }

    function excludeFrom(address updAds, bool isEx) public onlyOwner {
        isExcluded[updAds] = isEx;
    }

    function setAMM(address addrs, bool isamm) public onlyOwner {
        automatedMarketMakerPairs[addrs] = isamm;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer more than 0");

        if (limitsActive) {
            if (from != owner() && to != owner()) {
                if (!tradingActive) {
                    require(isExcluded[from], "Trading is not active.");
                }

                //when buy
                if (automatedMarketMakerPairs[from]) {
                    if (!isExcluded[to]) {
                        require(
                            amount <= maxTransactionAmount,
                            "Buy transfer amount exceeds the maxTransactionAmount."
                        );
                        require(
                            amount + balanceOf(to) <= maxWallet,
                            "Max wallet exceeded"
                        );
                    }
                }
                //when sell
                else if (automatedMarketMakerPairs[to]) {
                    if (!isExcluded[from]) {
                        require(
                            amount <= maxTransactionAmount,
                            "Sell transfer amount exceeds the maxTransactionAmount."
                        );
                    }
                } else {
                    //normal transfer
                    if (!isExcluded[to]) {
                        require(
                            amount + balanceOf(to) <= maxWallet,
                            "Max wallet exceeded"
                        );
                    }
                }
            }
        }

        super._transfer(from, to, amount);
    }
}
