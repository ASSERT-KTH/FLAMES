/*
  
  ███████╗████████╗██╗░░██╗███████╗██████╗░██████╗░░█████╗░███╗░░░███╗██████╗░
  ██╔════╝╚══██╔══╝██║░░██║██╔════╝██╔══██╗██╔══██╗██╔══██╗████╗░████║██╔══██╗
  █████╗░░░░░██║░░░███████║█████╗░░██████╔╝██████╦╝██║░░██║██╔████╔██║██████╦╝
  ██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██╔══██╗██╔══██╗██║░░██║██║╚██╔╝██║██╔══██╗
  ███████╗░░░██║░░░██║░░██║███████╗██║░░██║██████╦╝╚█████╔╝██║░╚═╝░██║██████╦╝
  ╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═════╝░░╚════╝░╚═╝░░░░░╚═╝╚═════╝░

  Welcome to the Etherbomb contract!

  This is the final version of the project I experimented on Arbitrum: https://arbiscan.io/token/0x695c39f61301e066cd85F53e2ae8282EEBdA5614

  This contract was designed to be a fun experiment in the world of DeFi.
  It generates engagement by incentivizing users to take care of their wallets.

  Facts:
    - No clog
    - No tax grab

  Rules:
    - Your bombs will explode after 10 hours of inactivity
    - If your bombs explode, your wallet will be nuked and your tokens locked forever
    - You can defuse your bombs at any time by using the defuse button to reset the timer or by receiving tokens
    - You can also enter the bunker by using the bunker button to protect your wallet from the explosion during 7 days
    - While in the bunker, you can't send or receive tokens


  Telegram: https://t.me/Etherbomb
  Twitter: https://twitter.com/EtherbombETH
  Website: https://etherbomb.xyz

  Made by t.me/thecryptoalchemist

*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IUniswapV2Router} from "./interfaces/IUniswapV2Router.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";

contract Etherbomb is ERC20, Ownable {
  uint256 public constant BUNKER_FEE = 0.01 ether;
  uint256 public constant TICK = 10 hours;
  uint256 public constant BUNKER_DURATION = 7 days;
  uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;

  uint256 public maxWalletAmount = INITIAL_SUPPLY / 200;
  uint256 public maxTxAmount = INITIAL_SUPPLY / 200;

  bool public tradingOpen = false;

  address public uniswapV2Pair;

  address payable private deployer;
  address payable private taxWallet;

  mapping(address => bool) public excludedFromMaxWallet;
  mapping(address => bool) public immune; // admin can set this to true to prevent explosion (e.g pair contract)
  mapping(address => uint256) private _nextExplosionTimestamp;
  mapping(address => uint256) private _inBunkerUntilTimestamp;

  IUniswapV2Router public uniswapV2Router =
    IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  event Defused(address indexed account, uint256 untilTimestamp);
  event EnteredBunker(address indexed account, uint256 untilTimestamp);

  constructor() ERC20("ETHERBOMB", "BOMBS") {
    deployer = payable(msg.sender);
    taxWallet = payable(msg.sender);

    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
      address(this),
      uniswapV2Router.WETH()
    );

    excludedFromMaxWallet[owner()] = true;
    excludedFromMaxWallet[address(this)] = true;
    excludedFromMaxWallet[uniswapV2Pair] = true;

    immune[owner()] = true;
    immune[address(this)] = true;
    immune[uniswapV2Pair] = true;

    _mint(msg.sender, INITIAL_SUPPLY);
  }

  function transfer(
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    return super.transfer(recipient, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    return super.transferFrom(sender, recipient, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    require(!hasExploded(from) || immune[from], "Etherbomb: sender exploded");
    require(!hasExploded(to) || immune[to], "Etherbomb: recipient exploded");
    require(!inBunker(from), "Etherbomb: sender in bunker");
    require(!inBunker(to), "Etherbomb: recipient in bunker");

    if (
      from != owner() &&
      to != owner() &&
      tx.origin != deployer &&
      from != address(this) &&
      to != address(this)
    ) {
      require(tradingOpen, "Etherbomb: trading not yet enabled");
      require(
        amount <= maxTxAmount,
        "Etherbomb: amount exceeds the maxTxAmount."
      );

      if (!excludedFromMaxWallet[to] && from != to) {
        require(
          balanceOf(to) + amount <= maxWalletAmount,
          "Etherbomb: max wallet amount exceeded"
        );
      }

      // if sender is emptying his wallet, reset their explosion timestamp because he has no more bombs
      if (balanceOf(from) == amount) {
        _nextExplosionTimestamp[from] = 0;
      }

      if (!immune[to]) {
        _nextExplosionTimestamp[to] = block.timestamp + TICK;
        emit Defused(to, _nextExplosionTimestamp[to]);
      }
    }

    super._beforeTokenTransfer(from, to, amount);
  }

  function defuse() external {
    require(balanceOf(msg.sender) > 0, "Etherbomb: you have no bombs");
    require(
      !hasExploded(msg.sender),
      "Etherbomb: too late, you already exploded"
    );
    require(!immune[msg.sender], "Etherbomb: you're immune");

    _nextExplosionTimestamp[msg.sender] = block.timestamp + TICK;
    emit Defused(msg.sender, _nextExplosionTimestamp[msg.sender]);
  }

  function enterBunker() external payable {
    require(msg.value >= BUNKER_FEE, "Etherbomb: not enough ether");
    require(balanceOf(msg.sender) > 0, "Etherbomb: you have no bombs");
    require(
      !hasExploded(msg.sender),
      "Etherbomb: too late, you already exploded"
    );
    require(!inBunker(msg.sender), "Etherbomb: you're already in bunker");
    require(!immune[msg.sender], "Etherbomb: you're immune");

    _inBunkerUntilTimestamp[msg.sender] = block.timestamp + BUNKER_DURATION;
    _nextExplosionTimestamp[msg.sender] = 0;

    emit EnteredBunker(msg.sender, _inBunkerUntilTimestamp[msg.sender]);
    (bool success, ) = taxWallet.call{value: address(this).balance}("");
    require(success, "Etherbomb: transfer failed");
  }

  function setImmunity(address account, bool value) external onlyOwner {
    immune[account] = value;
  }

  function setIsExcludedFromMaxWallet(
    address account,
    bool value
  ) external onlyOwner {
    excludedFromMaxWallet[account] = value;
  }

  function setMaxTxPercent(uint256 percent) external onlyOwner {
    require(percent >= 1, "Etherbomb: percent must be greater than 1");
    maxTxAmount = (INITIAL_SUPPLY * percent) / 100;
  }

  function setMaxWalletPercent(uint256 percent) external onlyOwner {
    require(percent >= 1, "Etherbomb: percent must be greater than 1");
    maxWalletAmount = (INITIAL_SUPPLY * percent) / 100;
  }

  function openTrading() external onlyOwner {
    require(!tradingOpen, "Etherbomb: trading already open");
    tradingOpen = true;
  }

  function removeLimits() external onlyOwner {
    maxTxAmount = INITIAL_SUPPLY;
    maxWalletAmount = INITIAL_SUPPLY;
  }

  function inBunker(address account) public view returns (bool) {
    return _inBunkerUntilTimestamp[account] > block.timestamp;
  }

  function hasExploded(address account) public view returns (bool) {
    return
      getSecondsLeft(account) == 0 && _nextExplosionTimestamp[account] != 0;
  }

  function getSecondsLeft(address account) public view returns (uint256) {
    uint256 nextExplosion = nextExplosionOf(account);

    return block.timestamp < nextExplosion ? nextExplosion : 0;
  }

  function nextExplosionOf(address account) public view returns (uint256) {
    uint256 nextExplosion = _nextExplosionTimestamp[account];
    uint256 inBunkerUntil = _inBunkerUntilTimestamp[account];

    if (inBunker(account)) {
      return inBunkerUntil > nextExplosion ? inBunkerUntil : nextExplosion;
    } else {
      return nextExplosion;
    }
  }

  function rescueETH(address to) external {
    require(msg.sender == deployer, "Etherbomb: only deployer can rescue");
    payable(to).transfer(address(this).balance);
  }

  function rescueTokens(address token, address to) external {
    require(msg.sender == deployer, "Etherbomb: only deployer can rescue");
    IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
  }

  receive() external payable {}
}
