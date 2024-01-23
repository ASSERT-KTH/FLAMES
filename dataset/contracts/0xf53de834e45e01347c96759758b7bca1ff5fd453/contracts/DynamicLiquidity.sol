// Dynamic Liquidity (DYLP)
//
// https://dynamicliquidity.com
// https://twitter.com/DynamicLiq
//
// 0.69% tax (1% slippage)
//
// TLDR;
//    - chart go up, liquidity go up, price impact down
//    - chart go down, liquidity go down, price impact up
//    - sell too fast/too much at once, rekt
//    - sell within 10 minutes of buying, rekt
//
// A liquidity experiment that provisions and deprovisions liquidity all in the contract and
// was built to trustlessly and explicitly punish full stackers, clip releasers, dumpers, jeets,
// and generally anyone who doesn't know how or desire to respect the technicals of a chart.
//
// The DYLP contract caches pertinent liquidity information on each transaction and will add
// to or remove liquidity over time in order to reward those respecting and buying into the chart
// and ultimately punish those who take actions to damage it. The contract will frontrun large sells
// with liquidity removal that increases price impact and reduces gains on said sells. The ETH & tokens
// retrieved from this liquidity removal are custodied in the contract and dynamically added back to the
// liquidity pool as buys come through and the chart goes back up over time.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract DynamicLiquidity is ERC20 {
  using SafeERC20 for IERC20;

  uint256 constant PRECISION = 10 ** 18;
  address immutable POOL;
  IUniswapV2Router02 immutable ROUTER;

  uint256 _lpCurr;
  uint256 _lpLastLPChange;
  uint256 _tokensLastLPChange;
  address _deployer;
  uint256 _lastTransfer;
  bool _lpChanging;
  bool _inactivity;

  mapping(address => uint256) _lastBuy;
  mapping(address => uint256) _lastSell;

  event LiquidityAdded(
    uint256 _tokensDesired,
    uint256 _ethDesired,
    uint256 _tokensActual,
    uint256 _ethActual
  );
  event LiquidityRemoved(uint256 _tokensRemoved, uint256 _ethRemoved);

  constructor(
    IUniswapV2Router02 _uniRouter,
    address __deployer
  ) ERC20('Dynamic Liquidity', 'DYLP') {
    _deployer = __deployer;
    ROUTER = _uniRouter;
    POOL = IUniswapV2Factory(ROUTER.factory()).createPair(
      address(this),
      ROUTER.WETH()
    );
    _mint(_msgSender(), 1_000_000 * 10 ** 18);
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal virtual override {
    _lastTransfer = block.timestamp;
    bool _buy = _from == POOL && _to != address(ROUTER);
    bool _sell = _to == POOL;
    uint256 _tax;
    if ((_buy || _sell) && !_inactivity) {
      _tax = (_amount * 69) / 10000; // 0.69%
      if (!_lpChanging && _sell) {
        _lpChanging = true;
        uint256 _lpChangeBase = (PRECISION * _amount) / totalSupply();
        if (
          _lpLastLPChange > 0 &&
          _lpCurr > _lpLastLPChange &&
          _tokensLastLPChange > _amount &&
          _lastBuy[_from] > _lastSell[_from] &&
          _lastBuy[_from] > 0 &&
          block.timestamp > _lastBuy[_from] + 10 minutes
        ) {
          _add(_lpChangeBase);
        } else {
          uint256 _percRev = 2 * _lpChangeBase;
          uint256 _percentRem = _percRev > PRECISION / 3
            ? PRECISION / 3
            : _percRev;
          _remove(_percentRem);
        }
        _lpChanging = false;
        _lastSell[_from] = block.timestamp;
        _storeLastLPChange(_amount);
      }
      if (_buy) {
        _lastBuy[_to] = block.timestamp;
      }
      super._transfer(_from, address(this), _tax);
    }
    _storeCurrentLP();
    super._transfer(_from, _to, _amount - _tax);
  }

  function _add(uint256 _percentage) internal {
    uint256 _tokensToAdd = (balanceOf(address(this)) * _percentage) / PRECISION;
    uint256 _ethToAdd = (address(this).balance * _percentage) / PRECISION;
    if (_tokensToAdd == 0 || _ethToAdd == 0) {
      return;
    }
    _approve(address(this), address(ROUTER), _tokensToAdd);
    (uint256 _actualAmountToken, uint256 _actualAmountETH, ) = ROUTER
      .addLiquidityETH{ value: _ethToAdd }(
      address(this),
      _tokensToAdd,
      0,
      0,
      address(this),
      block.timestamp
    );
    emit LiquidityAdded(
      _tokensToAdd,
      _ethToAdd,
      _actualAmountToken,
      _actualAmountETH
    );
  }

  function _remove(uint256 _percentage) internal {
    if (_lpBal() == 0) {
      return;
    }
    uint256 _balBefore = balanceOf(address(this));
    uint256 _removingLp = (_lpBal() * _percentage) / PRECISION;
    IERC20(POOL).approve(address(ROUTER), _removingLp);
    uint256 _amountETH = ROUTER.removeLiquidityETHSupportingFeeOnTransferTokens(
      address(this),
      _removingLp,
      0,
      0,
      address(this),
      block.timestamp
    );
    emit LiquidityRemoved(balanceOf(address(this)) - _balBefore, _amountETH);
  }

  function _storeCurrentLP() internal {
    (uint256 _wethBal, uint256 _thisBal) = _currentLp();
    _lpCurr = _thisBal == 0 ? 0 : (_wethBal * PRECISION) / _thisBal;
  }

  function _storeLastLPChange(uint256 _tokens) internal {
    (uint256 _wethBal, uint256 _thisBal) = _currentLp();
    _lpLastLPChange = _thisBal == 0 ? 0 : (_wethBal * PRECISION) / _thisBal;
    _tokensLastLPChange = _tokens;
  }

  function _currentLp() internal view returns (uint256, uint256) {
    uint256 _wethBal = IERC20(ROUTER.WETH()).balanceOf(POOL);
    uint256 _thisBal = balanceOf(POOL);
    return (_wethBal, _thisBal);
  }

  function _lpBal() internal view returns (uint256) {
    return IERC20(POOL).balanceOf(address(this));
  }

  // if inactive and has no buys/sells/transfers for 3+ hours, allow
  // withdrawal of LP/ETH. As long as the project remains active and pushing,
  // this cannot happen.
  function withdrawOnInactivity() external {
    require(block.timestamp > _lastTransfer + 3 hours, 'ACTIVITY');
    if (_lpBal() > 0) {
      IERC20(POOL).safeTransfer(_deployer, _lpBal());
    }
    uint256 _bal = address(this).balance;
    if (_bal > 0) {
      (bool _s, ) = payable(_deployer).call{ value: _bal }('');
      require(_s);
    }
    _inactivity = true;
  }

  receive() external payable {}
}
