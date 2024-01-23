// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/// @title BRRR Token - Get ready to make some noise with $BRRR – your fun token designed to echo the excitement of the Valkyrie ETF journey
contract BRRRToken is ERC20, Ownable {
    bool public tradingActivated;
    uint256 private tradingStartTime;

    // Initial Allocation Addresses
    address public operationsWallet;
    address public initialMarketingWallet;
    address public prolongedMarketingWallet;
    address public reserveWallet;

    address public wethTokenAddr;

    IUniswapV2Router02 public uniswapV2RouterInstance;
    address public uniswapV2TokenPair;
    uint256 public constant TOKEN_MAX_SUPPLY = 10_000_000_000 * 10 ** 18; // 10 billion tokens

    mapping(address => bool) private permittedAddresses;
    mapping(address => bool) public blockedAccounts;

    constructor(
        address router,
        address wethAddress,
        address operationsAddress,
        address initialMarketingAddress,
        address prolongedMarketingAddress,
        address reserveAddress
    ) ERC20("VALKYRIE BITCOIN FUND", "BRRR") {
        wethTokenAddr = wethAddress;

        operationsWallet = operationsAddress;
        initialMarketingWallet = initialMarketingAddress;
        prolongedMarketingWallet = prolongedMarketingAddress;
        reserveWallet = reserveAddress;

        // Allocate 80% of the total supply to the owner for liquidity
        _mint(msg.sender, (TOKEN_MAX_SUPPLY * 80) / 100);

        // Allocate 5% of the total supply to the operations wallet
        _mint(operationsWallet, (TOKEN_MAX_SUPPLY * 5) / 100);

        // Allocate 5% of the total supply to the initial marketing wallet
        _mint(initialMarketingWallet, (TOKEN_MAX_SUPPLY * 5) / 100);

        // Allocate 5% of the total supply to the prolonged marketing wallet
        _mint(prolongedMarketingWallet, (TOKEN_MAX_SUPPLY * 5) / 100);

        // Allocate 5% of the total supply to the reserve wallet
        _mint(reserveWallet, (TOKEN_MAX_SUPPLY * 5) / 100);

        // Create a uniswap pair for this new token
        uniswapV2RouterInstance = IUniswapV2Router02(router);
        uniswapV2TokenPair = IUniswapV2Factory(
            uniswapV2RouterInstance.factory()
        ).createPair(address(this), wethAddress);

        // Setting permitted addresses
        permittedAddresses[owner()] = true;
        permittedAddresses[address(this)] = true;
        permittedAddresses[router] = true;
        permittedAddresses[operationsWallet] = true;
        permittedAddresses[initialMarketingWallet] = true;
        permittedAddresses[prolongedMarketingWallet] = true;
        permittedAddresses[reserveWallet] = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "Cannot send from zero address");
        require(!blockedAccounts[sender], "Sender account is blocked");
        require(!blockedAccounts[recipient], "Recipient account is blocked");

        if (permittedAddresses[sender] || permittedAddresses[recipient]) {
            super._transfer(sender, recipient, amount);
            return;
        }

        // Check is trading is activated
        require(tradingActivated, "Trading is not activated");

        if (recipient == uniswapV2TokenPair || sender == uniswapV2TokenPair) {
            // Apply a 99% tax on trades that occur within 5 minutes of trading activation
            // This tax is specifically designed to prevent sniper bots and destructive trading
            // practices that often target new tokens in their initial trading phase

            if (block.timestamp < tradingStartTime + 5 minutes) {
                // Calculate the tax amount (99% of the transaction)
                uint256 taxAmount = (amount * 99) / 100;
                uint256 taxedAmount = amount - taxAmount;

                // Redirect the tax amount to the treasury or a specified wallet
                super._transfer(sender, reserveWallet, taxAmount);

                // Proceed with the transaction for the remaining amount after tax deduction
                super._transfer(sender, recipient, taxedAmount);
            } else {
                // If the transaction occurs more than 5 minutes after trading has been activated,
                // proceed with the transaction without applying any tax
                super._transfer(sender, recipient, amount);
            }
        } else {
            // If it's not a buy or sell transaction, proceed without tax
            super._transfer(sender, recipient, amount);
        }
    }

    /// @notice Activates trading, enabling token transfers
    function activateTrading() external onlyOwner {
        tradingActivated = true;
        tradingStartTime = block.timestamp;
    }

    /// @notice Adds multiple addresses to the blacklist
    /// @param accounts Array of addresses to be blacklisted
    function blacklists(address[] memory accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            blockedAccounts[accounts[i]] = true;
        }
    }

    /// @notice Removes multiple addresses from the blacklist
    /// @param accounts Array of addresses to be unblacklisted
    function unblacklists(address[] memory accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            blockedAccounts[accounts[i]] = false;
        }
    }

    // Function to update the operations wallet address
    function updateOperationsWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Invalid address");
        operationsWallet = newWallet;
    }

    // Function to update the initial marketing wallet address
    function updateInitialMarketingWallet(
        address newWallet
    ) external onlyOwner {
        require(newWallet != address(0), "Invalid address");
        initialMarketingWallet = newWallet;
    }

    // Function to update the prolonged marketing wallet address
    function updateProlongedMarketingWallet(
        address newWallet
    ) external onlyOwner {
        require(newWallet != address(0), "Invalid address");
        prolongedMarketingWallet = newWallet;
    }

    // Function to update the reserve wallet address
    function updateReserveWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Invalid address");
        reserveWallet = newWallet;
    }
}
