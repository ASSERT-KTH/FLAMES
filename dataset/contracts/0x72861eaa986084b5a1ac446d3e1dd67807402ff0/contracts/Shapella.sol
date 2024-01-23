// SPDX-License-Identifier: MIT

///Medium: https://link.medium.com/BUBMjaSmJyb
///Medium: https://link.medium.com/2BFEk8lILyb
///Twitter: https://twitter.com/ShapellaERC

pragma solidity 0.8.17;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Shapella is ERC20, Ownable {
  /*|| === STATE VARIABLES === ||*/
  address payable public marketingWallet;
  address payable public teamWallet;
  address payable public liqWallet;
  address public immutable uniswapV2Pair;
  IUniswapV2Router02 public immutable uniswapV2Router;
  bool private inSwapAndLiquify;
  BuyTax public buyTax;
  SellTax public sellTax;

  uint private constant _supply = 10000000;
  uint8 private constant _decimals = 9;
  string private constant _name = "Shapella Protocol";
  string private constant _symbol = "SHAPELLA";
  uint public tokensToSell = 100000 * 10 ** _decimals;
  uint256 public maxWalletAmount = 100000 * 10 ** _decimals;
  bool public contractSell = true;

  /*|| === STRUCTS === ||*/
  struct BuyTax {
    uint16 liquidityTax;
    uint16 marketingTax;
    uint16 totalTax;
  }

  struct SellTax {
    uint16 liquidityTax;
    uint16 marketingTax;
    uint16 totalTax;
  }

  /*|| === MAPPINGS === ||*/
  mapping(address => bool) public addressWhitelist;

  /*|| === EVENTS === ||*/
  event SwapAndLiquify(uint tokensSwapped, uint ethReceived, uint tokensIntoLiqudity);

  /*|| === CONSTRUCTOR === ||*/
  constructor(address payable _marketingWallet, address payable _liqWallet) ERC20(_name, _symbol) {
    _mint(msg.sender, (_supply * 10 ** _decimals));
    marketingWallet = _marketingWallet;
    liqWallet = _liqWallet;

    // Create uniswap pair
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;

    addressWhitelist[address(uniswapV2Router)] = true;
    addressWhitelist[msg.sender] = true;
    addressWhitelist[marketingWallet] = true;
    addressWhitelist[liqWallet] = true;

    buyTax = BuyTax(0, 90, 90);
    sellTax = SellTax(0, 90, 90);
  }

  /*|| === MODIFIERS === ||*/
  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  /*|| === RECIEVE FUNCTION === ||*/
  receive() external payable {}

  /*|| === EXTERNAL FUNCTIONS === ||*/

  function getIsWhitelisted(address _address) external view returns (bool) {
    return addressWhitelist[_address];
  }

  function setMarketingWallet(address payable _marketingWallet) external onlyOwner {
    require(_marketingWallet != address(0), "Address cannot be 0 address");
    marketingWallet = _marketingWallet;
  }

  function setLiqWallet(address payable _liqWallet) external onlyOwner {
    require(_liqWallet != address(0), "Address cannot be 0 address");
    liqWallet = _liqWallet;
  }

  function addToWhitelist(address _address) external onlyOwner {
    addressWhitelist[_address] = true;
  }

  function removeFromWhitelist(address _address) external onlyOwner {
    addressWhitelist[_address] = false;
  }

  function setContractSell(bool _contractSell) external onlyOwner {
    contractSell = _contractSell;
  }

  function setBuyTax(uint16 liquidityTax, uint16 marketingTax) external onlyOwner {
    uint16 totalTax = liquidityTax + marketingTax;
    require(totalTax < 100, "Total tax over 99");
    buyTax = BuyTax(liquidityTax, marketingTax, totalTax);
  }

  function setSellTax(uint16 liquidityTax, uint16 marketingTax) external onlyOwner {
    uint16 totalTax = liquidityTax + marketingTax;
    require(totalTax < 100, "Total tax over 99");
    sellTax = SellTax(liquidityTax, marketingTax, totalTax);
  }

  function setTokensToSellForTax(uint _tokensToSell) external onlyOwner {
    tokensToSell = _tokensToSell;
  }

  function setMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner {
    maxWalletAmount = _maxWalletAmount;
  }

  /*|| === INTERNAL FUNCTIONS === ||*/
  function _transfer(address from, address to, uint amount) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");

    /// If buy or sell
    if ((from == uniswapV2Pair || to == uniswapV2Pair) && !inSwapAndLiquify) {
      /// On sell and if tax swap enabled
      if (to == uniswapV2Pair && contractSell) {
        uint contractTokenBalance = balanceOf(address(this));
        /// If the contract balance reaches sell threshold
        if (contractTokenBalance >= tokensToSell) {
          uint16 totalTokenTax = buyTax.totalTax + sellTax.totalTax;

          uint liquidityTokenCut = (tokensToSell * (buyTax.liquidityTax + sellTax.liquidityTax)) / totalTokenTax;

          /// Add tokens to lp
          _swapAndLiquify(liquidityTokenCut);

          /// Swap marketing tokens for ETH
          _swapTokens(tokensToSell - liquidityTokenCut);

          (marketingWallet).call{ value: (address(this).balance) }("");
        }
      }

      uint transferAmount = amount;
      if (!(addressWhitelist[from] || addressWhitelist[to])) {
        uint fees;

        /// On sell
        if (to == uniswapV2Pair) {
          fees = sellTax.totalTax;

          /// On buy
        } else if (from == uniswapV2Pair) {
          fees = buyTax.totalTax;
        }
        uint tokenFees = (amount * fees) / 100;
        transferAmount -= tokenFees;

        if (to != uniswapV2Pair) require((transferAmount + balanceOf(to)) <= maxWalletAmount, "ERC20: balance amount exceeded max wallet amount limit");

        super._transfer(from, address(this), tokenFees);
      }

      super._transfer(from, to, transferAmount);
    } else {
      /// If not transfering to whitelisted address
      if (!addressWhitelist[to]) {
        require((amount + balanceOf(to)) <= maxWalletAmount, "ERC20: balance amount exceeded max wallet amount limit");
      }
      super._transfer(from, to, amount);
    }
  }

  /*|| === PRIVATE FUNCTIONS === ||*/

  function _swapTokens(uint tokenAmount) private lockTheSwap {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
  }

  function _swapAndLiquify(uint liquidityTokenCut) private lockTheSwap {
    uint ethHalf = (liquidityTokenCut / 2);
    uint tokenHalf = (liquidityTokenCut - ethHalf);

    uint balanceBefore = address(this).balance;

    _swapTokens(ethHalf);

    uint balanceAfter = (address(this).balance - balanceBefore);

    _addLiquidity(tokenHalf, balanceAfter);

    emit SwapAndLiquify(ethHalf, balanceAfter, tokenHalf);
  }

  function _addLiquidity(uint tokenAmount, uint ethAmount) private lockTheSwap {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(address(this), tokenAmount, 0, 0, liqWallet, block.timestamp);
  }
}
