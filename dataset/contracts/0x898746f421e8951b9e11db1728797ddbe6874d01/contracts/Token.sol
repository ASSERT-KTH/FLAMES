// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Welcome To Matched Betz
// Where Skill Meets Crypto Trading Mastery!
//
// mbetz.io
// https://t.me/matchedbetz
// https://twitter.com/matchedbetz

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";


contract Token is Context, IERC20, IERC20Metadata, Ownable {
    // erc20
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;

    // reflection
    uint256 private constant MAX = type(uint256).max;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    uint256 private constant _tTotal = 250000000 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    // constraints
    address public _managerAddress;
    address public uniswapV2Pair;
    bool public limited;
    uint256 public maxHoldingAmount;

    modifier onlyManager {
        require(msg.sender == _managerAddress, "Only manager can run this method");
        _;
    }

    constructor(address managerAddress) {
        _name = "Matched Betz";
        _symbol = "MBETZ";
        _managerAddress = managerAddress;
        maxHoldingAmount = _tTotal * 1 / 100;

        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0x0), msg.sender, _tTotal);
    }

    //   ___ _   _ ___ _____ ___  __  __
    //  / __| | | / __|_   _/ _ \|  \/  |
    // | (__| |_| \__ \ | || (_) | |\/| |
    //  \___|\___/|___/ |_| \___/|_|  |_|
    //
    /**
        On start max wallet size is 1% to avoid cheaters
    */
    function setRules(bool _limited, address _uniswapV2Pair) public onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
    }

    /**
        Takes ETH accidentally sent to contract
    */
    function withdrawEth() external onlyManager {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
        Takes any ERC20 accidentally sent to contract
    */
    function withdrawErc20(address tokenAddress) external onlyManager {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        // use broken IERC20
        IUsdt(tokenAddress).transfer(msg.sender, balance);
    }

    //  ___ ___  ___ ___ __
    // | __| _ \/ __|_  /  \
    // | _||   | (__ / | () |
    // |___|_|_\\___/___\__/
    //
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();

        return rAmount / currentRate;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        (uint256 rAmount, uint256 tAmount) = _getValues(amount);

        _rOwned[from] -= rAmount;
        if (_isExcluded[from]) {
            _tOwned[from] -= tAmount;
        }
        _rOwned[to] += rAmount;
        if (_isExcluded[to]) {
            _tOwned[to] += tAmount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    //  ___ ___ ___ _    ___ ___ _____ ___ ___  _  _
    // | _ | __| __| |  | __/ __|_   _|_ _/ _ \| \| |
    // |   | _|| _|| |__| _| (__  | |  | | (_) | .` |
    // |_|_|___|_| |____|___\___| |_| |___\___/|_|\_|
    //
    function excludeAccount(address account) external onlyManager {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rTotal -= rAmount;
        _tFeeTotal += tAmount;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;

        return (rAmount, tAmount);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /**
        Amount of reflected tokens
    */
    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }
}