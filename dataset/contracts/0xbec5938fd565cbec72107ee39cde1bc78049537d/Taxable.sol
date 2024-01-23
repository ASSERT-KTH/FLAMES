//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./BaseErc20.sol";

abstract contract Taxable is BaseErc20 {
    
    ITaxDistributor taxDistributor;

    bool public autoSwapTax;
    uint256 public minimumTimeBetweenSwaps;
    uint256 public minimumTokensBeforeSwap;
    mapping (address => bool) public excludedFromTax;
    uint256 swapStartTime;
    
    // Overrides
    
    function configure(address _owner) internal virtual override {
        excludedFromTax[_owner] = true;
        super.configure(_owner);
    }
    
    
    function calculateTransferAmount(address from, address to, uint256 value) internal virtual override returns (uint256) {
        
        uint256 amountAfterTax = value;

        if (excludedFromTax[from] == false && excludedFromTax[to] == false && launched) {
            if (exchanges[from]) {
                // we are BUYING
                amountAfterTax = taxDistributor.takeBuyTax(value);
            } else if (exchanges[to]) {
                // we are SELLING
                amountAfterTax = taxDistributor.takeSellTax(value);
            }
        }

        uint256 taxAmount = value - amountAfterTax;
        if (taxAmount > 0) {
            _balances[address(taxDistributor)] = _balances[address(taxDistributor)] + taxAmount;
            emit Transfer(from, address(taxDistributor), taxAmount);
        }
        
        return super.calculateTransferAmount(from, to, amountAfterTax);
    }


    function preTransfer(address from, address to, uint256 value) override virtual internal {
        uint256 timeSinceLastSwap = block.timestamp - taxDistributor.lastSwapTime();
        if (
            launched && 
            autoSwapTax && 
            exchanges[to] && 
            swapStartTime + 60 <= block.timestamp &&
            timeSinceLastSwap >= minimumTimeBetweenSwaps &&
            _balances[address(taxDistributor)] >= minimumTokensBeforeSwap &&
            taxDistributor.inSwap() == false
        ) {
            swapStartTime = block.timestamp;
            try taxDistributor.distribute() {} catch {}
        }
        super.preTransfer(from, to, value);
    }
    
    
    // Public methods
    
    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function sellTax() public view returns (uint256) {
        return taxDistributor.getSellTax();
    }

    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function buyTax() public view returns (uint256) {
        return taxDistributor.getBuyTax();
    }

    /**
     * @dev Return the address of the tax distributor contract
     */
    function taxDistributorAddress() public view returns (address) {
        return address(taxDistributor);
    }    
    
    
    // Admin methods
    
    function setExcludedFromTax(address who, bool enabled) external onlyOwner {
        excludedFromTax[who] = enabled;
        emit ConfigurationChanged(msg.sender, "Tax Exlusion List Changed");
    }

    function setTaxDistributionThresholds(uint256 minAmount, uint256 minTime) external onlyOwner {
        require(minimumTokensBeforeSwap > 1 * 10 ** decimals && minimumTokensBeforeSwap < 100_000 * 10 ** decimals, "Invalid minAmount value");
        require(minimumTimeBetweenSwaps > 1 minutes && minimumTimeBetweenSwaps < 1 days, "Invalid minTime value");
        minimumTokensBeforeSwap = minAmount;
        minimumTimeBetweenSwaps = minTime;
        emit ConfigurationChanged(msg.sender, "Distribution Thresholds Changed");
    }
    
    function setSellTax(string memory taxName, uint256 taxAmount) external onlyOwner {
        taxDistributor.setSellTax(taxName, taxAmount);
        emit ConfigurationChanged(msg.sender, "Sell Tax Changed");
    }

    function setBuyTax(string memory taxName, uint256 taxAmount) external onlyOwner {
        taxDistributor.setBuyTax(taxName, taxAmount);
        emit ConfigurationChanged(msg.sender, "Buy Tax Changed");
    }
    
    function setTaxWallet(string memory taxName, address wallet) external onlyOwner {
        taxDistributor.setTaxWallet(taxName, wallet);
        emit ConfigurationChanged(msg.sender, "Tax Wallet Changed");
    }
    
    function runSwapManually() external isLaunched {
        taxDistributor.distribute();
    }
}