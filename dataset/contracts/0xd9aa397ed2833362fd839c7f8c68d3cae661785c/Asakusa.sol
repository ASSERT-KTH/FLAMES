// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";


/*
 * @author ~ 🅧🅘🅟🅩🅔🅡 ~ (https://twitter.com/Xipzer | https://t.me/Xipzer)
 *
 * ░█████╗░░██████╗░█████╗░██╗░░██╗██╗░░░██╗░██████╗░█████╗░
 * ██╔══██╗██╔════╝██╔══██╗██║░██╔╝██║░░░██║██╔════╝██╔══██╗
 * ███████║╚█████╗░███████║█████═╝░██║░░░██║╚█████╗░███████║
 * ██╔══██║░╚═══██╗██╔══██║██╔═██╗░██║░░░██║░╚═══██╗██╔══██║
 * ██║░░██║██████╔╝██║░░██║██║░╚██╗╚██████╔╝██████╔╝██║░░██║
 * ╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚═════╝░╚═════╝░╚═╝░░╚═╝
 *
 */

contract Asakusa is Context, IERC20, Ownable
{
    using Address for address;

    string public name = "Asakusa";
    string public symbol = "ASAKU";

    uint public decimals = 18;
    uint public totalSupply = 1000000000 * 10 ** decimals;

    uint private maxTXN = (totalSupply * 15) / 1000;
    uint private maxWallet = (totalSupply * 15) / 1000;
    uint public swapThresholdMin = totalSupply / 5000;
    uint public swapThresholdMax = totalSupply / 1000;

    address public dexPair;
    IUniswapV2Router02 public dexRouter;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint) private balances;
    mapping (address => mapping (address => uint)) private allowances;

    mapping (address => bool) private isCaughtMEV;
    mapping (address => bool) private isFeeExempt;
    mapping (address => bool) private isTxnLimitExempt;
    mapping (address => bool) private isWalletLimitExempt;
    mapping (address => bool) public isMarketPair;

    struct Fees
    {
        uint inFee;
        uint outFee;
        uint transferFee;
    }

    struct FeeSplit
    {
        uint marketing;
        uint development;
    }

    struct FeeReceivers
    {
        address payable marketing;
        address payable development;
    }

    Fees public fees;
    FeeSplit public feeSplit;
    FeeReceivers public feeReceivers;

    bool public tradingEnabled;
    bool public protectionRenounced;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    bool public swapAndLiquifyByLimitOnly;

    event SwapAndLiquifyStatusUpdated(bool status);
    event SwapAndLiquifyByLimitStatusUpdated(bool status);
    event SwapTokensForETH(uint amountIn, address[] path);

    modifier lockTheSwap
    {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor()
    {
        dexRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexPair = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());

        allowances[address(this)][address(dexRouter)] = type(uint).max;

        fees.inFee = 1500;
        fees.outFee = 3500;
        fees.transferFee = 3500;

        feeReceivers.marketing = payable(0xb9Ff4ba6C638838ad09Ba9994a94278E11BFFa33);
        feeReceivers.development = payable(0xfF7372EF917f6242c3e71048Bda9322ec5da4973);

        feeSplit.marketing = 6000;
        feeSplit.development = 4000;

        isFeeExempt[owner()] = true;
        isFeeExempt[address(0)] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[feeReceivers.marketing] = true;
        isFeeExempt[feeReceivers.development] = true;

        isTxnLimitExempt[owner()] = true;
        isTxnLimitExempt[address(0)] = true;
        isTxnLimitExempt[DEAD] = true;
        isTxnLimitExempt[address(this)] = true;
        isTxnLimitExempt[feeReceivers.marketing] = true;
        isTxnLimitExempt[feeReceivers.development] = true;

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(0)] = true;
        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[feeReceivers.marketing] = true;
        isWalletLimitExempt[feeReceivers.development] = true;

        isWalletLimitExempt[address(dexPair)] = true;
        isMarketPair[address(dexPair)] = true;

        swapAndLiquifyEnabled = true;
        swapAndLiquifyByLimitOnly = true;

        balances[_msgSender()] = totalSupply;
        emit Transfer(address(0), _msgSender(), totalSupply);
    }

    function balanceOf(address wallet) public view override returns (uint)
    {
        return balances[wallet];
    }

    function allowance(address owner, address spender) public view override returns (uint)
    {
        return allowances[owner][spender];
    }

    function getCirculatingSupply() public view returns (uint)
    {
        return totalSupply - balanceOf(address(0)) - balanceOf(DEAD);
    }

    function getMEVStatus(address wallet) public view returns (bool)
    {
        return isCaughtMEV[wallet];
    }

    function setWalletFeeStatus(address wallet, bool status) public onlyOwner()
    {
        isFeeExempt[wallet] = status;
    }

    function setWalletTxnStatus(address wallet, bool status) public onlyOwner()
    {
        isTxnLimitExempt[wallet] = status;
    }

    function setWalletLimitStatus(address wallet, bool status) public onlyOwner()
    {
        isWalletLimitExempt[wallet] = status;
    }

    function setMarketPairStatus(address wallet, bool status) public onlyOwner()
    {
        isMarketPair[wallet] = status;
    }

    function setMaxTXN(uint value) public onlyOwner()
    {
        require(value >= totalSupply / 10000, "ERROR: Minimum txn must be greater than 0.01% of total supply!");

        maxTXN = value;
    }

    function setMaxWallet(uint value) public onlyOwner()
    {
        require(value >= totalSupply / 10000, "ERROR: Minimum wallet size must be greater than 0.01% of total supply!");

        maxWallet = value;
    }

    function enableTrading() public onlyOwner()
    {
        require(!tradingEnabled, "ERROR: Trading is already enabled!");
        tradingEnabled = true;
    }

    function removeMaxTXN() public onlyOwner()
    {
        maxTXN = totalSupply;
    }

    function removeMaxWallet() public onlyOwner()
    {
        maxWallet = totalSupply;
    }

    function renounceMEVProtection() public onlyOwner()
    {
        require(!protectionRenounced, "ERROR: Anti-MEV system is already renounced!");
        protectionRenounced = true;
    }

    function setCaughtMEV(address[] memory wallets, bool status) public onlyOwner()
    {
        require(!protectionRenounced, "ERROR: Anti-MEV system is permanently disabled!");
        require(wallets.length <= 200, "ERROR: Maximum wallets at once is 200!");

        for (uint i = 0; i < wallets.length; i++)
            isCaughtMEV[wallets[i]] = status;
    }

    function setFees(uint inFee, uint outFee, uint transferFee) public onlyOwner()
    {
        require(inFee <= 5000 && outFee <= 5000 && transferFee <= 5000, "ERROR: Maximum directional fee is 50%!");

        fees.inFee = inFee;
        fees.outFee = outFee;
        fees.transferFee = transferFee;
    }

    function setFeeSplit(uint marketing, uint development) public onlyOwner()
    {
        require(marketing <= 10000 && development <= 10000, "ERROR: Fee split must not exceed 100%!");
        require(marketing + development <= 10000, "ERROR: Combined fee must not exceed 100%!");

        feeSplit.marketing = marketing;
        feeSplit.development = development;
    }

    function setFeeReceivers(address marketing, address development) public onlyOwner()
    {
        require(marketing != address(0) && development != address(0), "ERROR: Fee receiver must not be NULL address!");

        isFeeExempt[feeReceivers.marketing] = false;
        isFeeExempt[feeReceivers.development] = false;

        feeReceivers.marketing = payable(marketing);
        feeReceivers.development = payable(development);

        isFeeExempt[feeReceivers.marketing] = true;
        isFeeExempt[feeReceivers.development] = true;
    }

    function setSwapThresholds(uint swapMin, uint swapMax) public onlyOwner()
    {
        swapThresholdMin = swapMin;
        swapThresholdMax = swapMax;
    }

    function setSwapAndLiquifyStatus(bool status) public onlyOwner()
    {
        swapAndLiquifyEnabled = status;
        emit SwapAndLiquifyStatusUpdated(status);
    }

    function setSwapAndLiquifyByLimitStatus(bool status) public onlyOwner()
    {
        swapAndLiquifyByLimitOnly = status;
        emit SwapAndLiquifyByLimitStatusUpdated(status);
    }

    function approve(address spender, uint amount) public override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint amount) private
    {
        require(owner != address(0), "ERROR: Approve from the zero address!");
        require(spender != address(0), "ERROR: Approve to the zero address!");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint amount) public override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool)
    {
        if (allowances[sender][_msgSender()] != type(uint256).max)
            allowances[sender][_msgSender()] -= amount;

        return _transfer(sender, recipient, amount);
    }

    function transferToAddressNative(address payable recipient, uint amount) private
    {
        require(recipient != address(0), "SolarGuard: Cannot send to the 0 address!");

        recipient.call{ value: amount }("");
    }

    function _transfer(address sender, address recipient, uint amount) private returns (bool)
    {
        require(sender != address(0), "ERROR: Transfer from the zero address!");
        require(recipient != address(0), "ERROR: Transfer to the zero address!");
        require(!isCaughtMEV[recipient] && !isCaughtMEV[sender], "ERROR: Transfers are not permitted!");

        if (inSwapAndLiquify)
        {
            unchecked
            {
                require(amount <= balances[sender], "ERROR: Insufficient balance!");
                balances[sender] -= amount;
            }

            balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);
            return true;
        }
        else
        {
            if (!isFeeExempt[sender] && !isFeeExempt[recipient])
                require(tradingEnabled, "ERROR: Trading has not yet been enabled!");

            if (!isTxnLimitExempt[sender] && !isTxnLimitExempt[recipient])
                require(amount <= maxTXN, "ERROR: Transfer amount exceeds the maxTXN!");

            uint contractTokenBalance = balanceOf(address(this));
            if (!inSwapAndLiquify && swapAndLiquifyEnabled && !isMarketPair[sender] && contractTokenBalance >= swapThresholdMin)
            {
                if (swapAndLiquifyByLimitOnly)
                    contractTokenBalance = min(amount, min(contractTokenBalance, swapThresholdMax));

                swapAndLiquify(contractTokenBalance);
            }

            unchecked
            {
                require(amount <= balances[sender], "ERROR: Insufficient balance!");
                balances[sender] -= amount;
            }

            uint finalAmount = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, recipient, amount);

            if (!isWalletLimitExempt[recipient])
                require(balanceOf(recipient) + finalAmount <= maxWallet, "ERROR: Transfer amount must not exceed max wallet conditions!");

            balances[recipient] += finalAmount;

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function swapAndLiquify(uint amount) private lockTheSwap
    {
        swapTokensForETH(amount);
        uint amountReceived = address(this).balance;

        uint marketingAmount = (amountReceived * feeSplit.marketing) / 10000;
        uint developmentAmount = (amountReceived * feeSplit.development) / 10000;

        if (marketingAmount > 0)
            transferToAddressNative(feeReceivers.marketing, marketingAmount);
        if (developmentAmount > 0)
            transferToAddressNative(feeReceivers.development, developmentAmount);
    }

    function swapTokensForETH(uint amount) private
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        try dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp)
        {
            emit SwapTokensForETH(amount, path);
        }
        catch
        {
            return;
        }
    }

    function takeFee(address sender, address recipient, uint amount) internal returns (uint)
    {
        uint feeAmount = 0;

        if (isMarketPair[sender])
            feeAmount = (amount * fees.inFee) / 10000;
        else if (isMarketPair[recipient])
            feeAmount = (amount * fees.outFee) / 10000;
        else
            feeAmount = (amount * fees.transferFee) / 10000;

        if (feeAmount > 0)
        {
            balances[address(this)] += feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount - feeAmount;
    }

    function withdrawStuckNative(address recipient, uint amount) public onlyOwner()
    {
        require(recipient != address(0), "ERROR: Cannot send to the 0 address!");
        payable(recipient).transfer(amount);
    }

    function withdrawForeignToken(address tokenAddress, address recipient, uint amount) public onlyOwner()
    {
        require(recipient != address(0), "ERROR: Cannot send to the 0 address!");
        IERC20(tokenAddress).transfer(recipient, amount);
    }

    function min(uint a, uint b) private pure returns (uint)
    {
        return (a >= b) ? b : a;
    }

    receive() external payable {}
}