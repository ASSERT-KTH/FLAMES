//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./BaseErc20Min.sol";
import "./AddressLibrary.sol";
import "./Interfaces.sol";

interface IBasicTaxDistributor {
    receive() external payable;
    function lastSwapTime() external view returns (uint256);
    function inSwap() external view returns (bool);
    function createWalletTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external;
    function distribute() external payable;
    function getSellTax() external view returns (uint256);
    function getBuyTax() external view returns (uint256);
    function getTaxWallet(string memory taxName) external view returns(address);
    function setTaxWallet(string memory taxName, address wallet) external;
    function setSellTax(string memory taxName, uint256 taxPercentage) external;
    function setBuyTax(string memory taxName, uint256 taxPercentage) external;
    function takeSellTax(uint256 value) external returns (uint256);
    function takeBuyTax(uint256 value) external returns (uint256);
}

abstract contract Taxable is BaseErc20 {
    
    IBasicTaxDistributor internal taxDistributor;

    bool internal autoSwapTax;
    uint256 internal minimumTimeBetweenSwaps;
    uint256 internal minimumTokensBeforeSwap;
    mapping (address => bool) internal excludedFromTax;
    uint256 private swapStartTime;
    
    // Overrides
    
    function configure(address _owner) internal virtual override {
        excludedFromTax[owner] = true;
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
    function sellTax() external view returns (uint256) {
        return taxDistributor.getSellTax();
    }

    /**
     * @dev Return the current total sell tax from the tax distributor
     */
    function buyTax() external view returns (uint256) {
        return taxDistributor.getBuyTax();
    }

    /**
     * @dev Return the address of the tax distributor contract
     */
    function taxDistributorAddress() external view returns (address) {
        return address(taxDistributor);
    }    
    
    
    // Admin methods

    function setAutoSwaptax(bool enabled) external onlyOwner {
        autoSwapTax = enabled;
    }

    function setExcludedFromTax(address who, bool enabled) external onlyOwner {
        require(exchanges[who] == false || enabled == false, "Cannot exclude an exchange from tax");
        excludedFromTax[who] = enabled;
    }

    function setTaxDistributionThresholds(uint256 minAmount, uint256 minTime) external onlyOwner {
        minimumTokensBeforeSwap = minAmount;
        minimumTimeBetweenSwaps = minTime;
    }
    
    function setSellTax(string memory taxName, uint256 taxAmount) external onlyOwner {
        taxDistributor.setSellTax(taxName, taxAmount);
    }

    function setBuyTax(string memory taxName, uint256 taxAmount) external onlyOwner {
        taxDistributor.setBuyTax(taxName, taxAmount);
    }
    
    function setTaxWallet(string memory taxName, address wallet) external onlyOwner {
        taxDistributor.setTaxWallet(taxName, wallet);
    }
    
    function runSwapManually() external isLaunched {
        taxDistributor.distribute();
    }
}

contract BasicTaxDistributor is IBasicTaxDistributor {
    using Address for address;

    address immutable private tokenPair;
    address immutable private routerAddress;
    address immutable private _token;
    address immutable private _wbnb;

    IDEXRouter private _router;

    bool public override inSwap;
    uint256 public override lastSwapTime;

    uint256 immutable private maxSellTax;
    uint256 immutable private maxBuyTax;

    struct Tax {
        string taxName;
        uint256 buyTaxPercentage;
        uint256 sellTaxPercentage;
        uint256 taxPool;
        address location;
        uint256 share;
        bool convertToNative;
    }
    Tax[] internal taxes;

    event TaxesDistributed(uint256 tokensSwapped, uint256 ethReceived);
    event DistributionError(string text);

    modifier onlyToken() {
        require(msg.sender == _token, "no permissions");
        _;
    }

    modifier swapLock() {
        require(inSwap == false, "already swapping");
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (address router, address pair, address wbnb, uint256 _maxSellTax, uint256 _maxBuyTax) {
        require(wbnb != address(0), "pairedToken cannot be 0 address");
        require(pair != address(0), "pair cannot be 0 address");
        require(router != address(0), "router cannot be 0 address");
        _token = msg.sender;
        _wbnb = wbnb;
        _router = IDEXRouter(router);
        maxSellTax = _maxSellTax;
        maxBuyTax = _maxBuyTax;
        tokenPair = pair;
        routerAddress = router;
    }

    receive() external override payable {}

    function createWalletTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) external override onlyToken {
        require(checkTaxExists(name) == false, "This tax already exists");
        taxes.push(Tax(name, buyTax, sellTax, 0, wallet, 0, convertToNative));
    }

    function checkTaxExists(string memory taxName) private view returns(bool) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (compareStrings(taxes[i].taxName, taxName)) {
                return true;
            }
        }
        return false;
    }

    function distribute() external payable override onlyToken swapLock {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _wbnb;
        IERC20 token = IERC20(_token);

        uint256 totalTokens;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].convertToNative) {
                totalTokens += taxes[i].taxPool;
            }
        }
        totalTokens = checkTokenAmount(token, totalTokens);

        uint256[] memory amts = _router.swapExactTokensForETH(
            totalTokens,
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        uint256 amountBNB = address(this).balance;

        if (totalTokens != amts[0] || amountBNB != amts[1] ) {
            emit DistributionError("Unexpected amounts returned from swap");
        }

        // Calculate the distribution
        uint256 toDistribute = amountBNB;
        for (uint256 i = 0; i < taxes.length; i++) {

            if (taxes[i].convertToNative) {
                if (i == taxes.length - 1) {
                    taxes[i].share = toDistribute;
                } else {
                    uint256 share = (amountBNB * taxes[i].taxPool) / totalTokens;
                    taxes[i].share = share;
                    toDistribute = toDistribute - share;
                }
            }
        }

        // Distribute the coins
        for (uint256 i = 0; i < taxes.length; i++) {        
                if (taxes[i].convertToNative) {
                    Address.sendValue(payable(taxes[i].location), taxes[i].share);
                } else {
                    require(token.transfer(taxes[i].location, checkTokenAmount(token, taxes[i].taxPool)), "could not transfer tokens");
                }

            taxes[i].taxPool = 0;
            taxes[i].share = 0;
        }

        // Remove any leftoever tokens
        if (address(this).balance > 0) {
            Address.sendValue(payable(_token), address(this).balance);
        }

        if (token.balanceOf(address(this)) > 0) {
            token.transfer(_token, token.balanceOf(address(this)));
        }

        emit TaxesDistributed(totalTokens, amountBNB);

        lastSwapTime = block.timestamp;
    }

    function getSellTax() public override onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].sellTaxPercentage;
        }
        return taxAmount;
    }

    function getBuyTax() public override onlyToken view returns (uint256) {
        uint256 taxAmount;
        for (uint256 i = 0; i < taxes.length; i++) {
            taxAmount += taxes[i].buyTaxPercentage;
        }
        return taxAmount;
    }

    function getTaxWallet(string memory taxName)external override view onlyToken returns (address)  {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (compareStrings(taxes[i].taxName, taxName)) {
                return taxes[i].location;
            }
        }
        revert("could not find tax");
    }
    
    function setTaxWallet(string memory taxName, address wallet) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].location = wallet;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
    }

    function setSellTax(string memory taxName, uint256 taxPercentage) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].sellTaxPercentage = taxPercentage;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
        require(getSellTax() <= maxSellTax, "tax cannot be set this high");
    }

    function setBuyTax(string memory taxName, uint256 taxPercentage) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            //if (taxes[i].taxName == taxName) {
            if (compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].buyTaxPercentage = taxPercentage;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
        require(getBuyTax() <= maxBuyTax, "tax cannot be set this high");
    }

    function takeSellTax(uint256 value) external override onlyToken returns (uint256) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].sellTaxPercentage > 0) {
                uint256 taxAmount = (value * taxes[i].sellTaxPercentage) / 10000;
                taxes[i].taxPool += taxAmount;
                value = value - taxAmount;
            }
        }
        return value;
    }

    function takeBuyTax(uint256 value) external override onlyToken returns (uint256) {
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].buyTaxPercentage > 0) {
                uint256 taxAmount = (value * taxes[i].buyTaxPercentage) / 10000;
                taxes[i].taxPool += taxAmount;
                value = value - taxAmount;
            }
        }
        return value;
    }
    
    
    // Private methods
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function checkTokenAmount(IERC20 token, uint256 amount) private view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));
        if (balance > amount) {
            return amount;
        }
        return balance;
    }
}
