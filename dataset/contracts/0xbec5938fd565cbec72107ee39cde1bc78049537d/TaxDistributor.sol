//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";

contract TaxDistributor is ITaxDistributor {

    address immutable public tokenPair;
    address immutable public routerAddress;
    address immutable private _token;
    address immutable private _pairedToken;

    IDEXRouter private _router;

    bool public override inSwap;
    uint256 public override lastSwapTime;

    uint256 immutable public maxSellTax;
    uint256 immutable public maxBuyTax;

    enum TaxType { WALLET, DIVIDEND, LIQUIDITY, DISTRIBUTOR, BURN }
    struct Tax {
        string taxName;
        uint256 buyTaxPercentage;
        uint256 sellTaxPercentage;
        uint256 taxPool;
        TaxType taxType;
        address location;
        uint256 share;
        bool convertToNative;
    }
    Tax[] public taxes;

    event TaxesDistributed(uint256 tokensSwapped, uint256 ethReceived);
    event ConfigurationChanged(address indexed owner, string option);
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

    constructor (address router, address pair, address pairedToken, uint256 _maxSellTax, uint256 _maxBuyTax) {
        require(pairedToken != address(0), "pairedToken cannot be 0 address");
        require(pair != address(0), "pair cannot be 0 address");
        require(router != address(0), "router cannot be 0 address");

        _token = msg.sender;
        _pairedToken = pairedToken;
        _router = IDEXRouter(router);
        maxSellTax = _maxSellTax;
        maxBuyTax = _maxBuyTax;
        tokenPair = pair;
        routerAddress = router;

        IERC20(pairedToken).approve(router, 2**256 - 1);
    }

    receive() external override payable {}

    function createWalletTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.WALLET, wallet, 0, convertToNative));
        emit ConfigurationChanged(msg.sender, "Tax Created");
    }

    function createDistributorTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet, bool convertToNative) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.DISTRIBUTOR, wallet, 0, convertToNative));
        emit ConfigurationChanged(msg.sender, "Tax Created");
    }
    
    function createDividendTax(string memory name, uint256 buyTax, uint256 sellTax, address dividendDistributor, bool convertToNative) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.DIVIDEND, dividendDistributor, 0, convertToNative));
        emit ConfigurationChanged(msg.sender, "Tax Created");
    }
    
    function createBurnTax(string memory name, uint256 buyTax, uint256 sellTax) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.BURN, address(0), 0, false));
        emit ConfigurationChanged(msg.sender, "Tax Created");
    }

    function createLiquidityTax(string memory name, uint256 buyTax, uint256 sellTax, address wallet) public override onlyToken {
        taxes.push(Tax(name, buyTax, sellTax, 0, TaxType.LIQUIDITY, wallet, 0, false));
        emit ConfigurationChanged(msg.sender, "Tax Created");
    }

    function distribute() public payable override onlyToken swapLock {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = _pairedToken;
        IERC20 token = IERC20(_token);
        IERC20 pairedToken = IERC20(_pairedToken);

        uint256 totalTokens;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].taxType == TaxType.LIQUIDITY) {
                uint256 half = taxes[i].taxPool / 2;
                totalTokens += taxes[i].taxPool - half;
            } else if (taxes[i].convertToNative) {
                totalTokens += taxes[i].taxPool;
            }
        }
        totalTokens = checkTokenAmount(token, totalTokens);
      
        if (checkTokenAmount(token, totalTokens) != totalTokens) {
            emit DistributionError("Insufficient tokens to swap. Please add more tokens");
            return;
        }

        uint256[] memory amts = _router.swapExactTokensForTokens(
            totalTokens,
            0,
            path,
            address(this),
            block.timestamp + 300
        );

        uint256 amountBNB = pairedToken.balanceOf(address(this));

        if (totalTokens != amts[0] || amountBNB != amts[1] ) {
            emit DistributionError("Unexpected amounts returned from swap");
        }

        // Calculate the distribution
        uint256 toDistribute = amountBNB;
        for (uint256 i = 0; i < taxes.length; i++) {

            if (taxes[i].convertToNative || taxes[i].taxType == TaxType.LIQUIDITY) {
                if (i == taxes.length - 1) {
                    taxes[i].share = toDistribute;
                } else if (taxes[i].taxType == TaxType.LIQUIDITY) {
                    uint256 half = taxes[i].taxPool / 2;
                    uint256 share = (amountBNB * (taxes[i].taxPool - half)) / totalTokens;
                    taxes[i].share = share;
                    toDistribute = toDistribute - share;
                } else {
                    uint256 share = (amountBNB * taxes[i].taxPool) / totalTokens;
                    taxes[i].share = share;
                    toDistribute = toDistribute - share;
                }
            }
        }

        // Distribute the coins
        for (uint256 i = 0; i < taxes.length; i++) {
            
            if (taxes[i].taxType == TaxType.WALLET) {
                if (taxes[i].convertToNative) {
                    pairedToken.transfer(taxes[i].location, taxes[i].share);
                } else {
                    token.transfer(taxes[i].location, checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.DISTRIBUTOR) {
                if (taxes[i].convertToNative) {
                    pairedToken.transfer(taxes[i].location, taxes[i].share);
                } else {
                    token.approve(taxes[i].location, taxes[i].taxPool);
                    IWalletDistributor(taxes[i].location).receiveToken(_token, address(this), checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.DIVIDEND) {
               if (taxes[i].convertToNative) {
                    IDividendDistributor(taxes[i].location).depositToken(address(this), checkTokenAmount(pairedToken, taxes[i].taxPool));
                } else {
                    IDividendDistributor(taxes[i].location).depositToken(address(this), checkTokenAmount(token, taxes[i].taxPool));
                }
            }
            else if (taxes[i].taxType == TaxType.BURN) {
                IBurnable(_token).burn(address(this), checkTokenAmount(token, taxes[i].taxPool));
            }
            else if (taxes[i].taxType == TaxType.LIQUIDITY) {
                if(taxes[i].share > 0){
                    uint256 half = checkTokenAmount(token, taxes[i].taxPool / 2);
                    _router.addLiquidity(
                        _token,
                        _pairedToken,
                        half,
                        taxes[i].share,
                        0,
                        0,
                        taxes[i].location,
                        block.timestamp + 300
                    );
                }
            }
            
            taxes[i].taxPool = 0;
            taxes[i].share = 0;
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
    
    function setTaxWallet(string memory taxName, address wallet) external override onlyToken {
        bool updated;
        for (uint256 i = 0; i < taxes.length; i++) {
            if (taxes[i].taxType == TaxType.WALLET && compareStrings(taxes[i].taxName, taxName)) {
                taxes[i].location = wallet;
                updated = true;
            }
        }
        require(updated, "could not find tax to update");
        emit ConfigurationChanged(msg.sender, "Tax Wallet Changed");
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
        emit ConfigurationChanged(msg.sender, "Sell Tax Changed");
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
        emit ConfigurationChanged(msg.sender, "Buy Tax Changed");
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
