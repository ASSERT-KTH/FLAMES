// SPDX-License-Identifier: MIT
// Copyright (c) 2022-2023 Fellowship

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./LimitedPaymentDistributor.sol";
import "./Mintable.sol";
import "./TimedSale.sol";

contract DutchAuctionRefundMinter is LimitedPaymentDistributor, TimedSale {
    uint256 public immutable walletLimit;
    uint256 public immutable mintLimit;
    string private limitRevertMessage;

    /// @notice ERC-721 contract whose tokens are minted by this auction
    /// @dev Must implement Mintable and number tokens sequentially from zero
    Mintable public tokenContract;

    /// @notice Starting price for the Dutch auction (in wei)
    uint256 public startPrice;

    /// @notice Resting price where price descent ends (in wei)
    uint256 public restPrice;

    /// @notice Lowest price at which a token was minted (in wei)
    uint256 public lowestPrice;

    /// @notice Amount that the price drops (in wei) every slot (every 12 seconds)
    uint256 public priceDropPerSlot;

    /// @notice Number of reserveTokens that have been minted
    uint256 public reserveCount = 0;

    /// @notice Number of tokens that have been minted per address
    mapping(address => uint256) public mintCount;
    /// @notice Total amount paid to mint per address
    mapping(address => uint256) public mintPayment;

    uint256 private previousPayment = 0;

    /// @notice An event emitted upon token purchases
    event Purchase(address purchaser, uint256 tokenId, uint256 price);

    /// @notice An event emitted when reserve tokens are minted
    event Reservation(address recipient, uint256 quantity, uint256 totalReserved);

    /// @notice An event emitted when a refund is sent to a minter
    event Refund(address recipient, uint256 amount);

    /// @notice An error returned when the auction has reached its `mintLimit`
    error SoldOut();

    constructor(
        Mintable tokenContract_,
        uint256 startTime_,
        uint256 startPrice_,
        uint256 restPrice_,
        uint256 priceDrop,
        uint256 walletLimit_,
        uint256 mintLimit_
    ) TimedSale(startTime_) {
        // CHECKS inputs
        require(address(tokenContract_) != address(0), "Token contract must not be the zero address");

        require(startPrice_ > 1e15, "Start price too low: check that prices are in wei");
        require(restPrice_ > 1e15, "Rest price too low: check that prices are in wei");
        require(startPrice_ >= restPrice_, "Start price must not be lower than rest price");

        require(walletLimit_ < mintLimit_, "Mint limit should be greater than wallet limit");

        uint256 priceDifference;
        unchecked {
            priceDifference = startPrice_ - restPrice_;
        }
        require(priceDrop * 25 <= priceDifference, "Auction must last at least 5 minutes");
        require(priceDrop * (5 * 60 * 24) >= priceDifference, "Auction must not last longer than 24 hours");

        // EFFECTS
        tokenContract = tokenContract_;
        lowestPrice = startPrice = startPrice_;
        restPrice = restPrice_;
        priceDropPerSlot = priceDrop;

        mintLimit = mintLimit_;
        walletLimit = walletLimit_ != 0 ? walletLimit_ : mintLimit_;
        limitRevertMessage = string.concat("Limited to ", Strings.toString(walletLimit), " purchases per wallet");
    }

    // PUBLIC FUNCTIONS

    /// @notice Mint a token on the `tokenContract` contract. Must include at least `currentPrice`.
    function mint() public payable virtual started whenNotPaused {
        // CHECKS state and inputs
        uint totalCount = tokenContract.totalSupply();
        if (totalCount >= mintLimit) revert SoldOut();
        uint256 price = msg.value;
        require(price >= currentPrice(), "Insufficient payment");
        require(mintCount[msg.sender] < walletLimit, limitRevertMessage);

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: mintCount cannot exceed walletLimit
            mintCount[msg.sender]++;
            // Unchecked arithmetic: can't exceed this.balance; not expected to exceed walletLimit * startPrice
            mintPayment[msg.sender] += price;
        }

        if (price < lowestPrice) {
            lowestPrice = price;
        }

        emit Purchase(msg.sender, totalCount, price);

        // INTERACTIONS: call mint on known contract (tokenContract.mint contains no external interactions)
        tokenContract.mint(msg.sender);
    }

    /// @notice Mint multiple tokens on the `tokenContract` contract. Must pay at least `currentPrice` * `quantity`.
    /// @param quantity The number of tokens to mint: must not be greater than `walletLimit`
    function mintMultiple(uint256 quantity) public payable virtual started whenNotPaused {
        // CHECKS state and inputs
        uint firstId = tokenContract.totalSupply();
        if (firstId >= mintLimit) revert SoldOut();
        uint256 alreadyMinted = mintCount[msg.sender];
        require(quantity > 0, "Must mint at least one token");
        require(quantity <= walletLimit && alreadyMinted < walletLimit, limitRevertMessage);

        uint256 payment = msg.value;
        uint256 price = payment / quantity;
        require(price >= currentPrice(), "Insufficient payment");

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: firstId + quantity is less than mintLimit + walletLimit
            if (firstId + quantity > mintLimit) {
                // Reduce quantity to the remaining supply
                // Unchecked arithmetic: already checked that firstId is less than mintLimit
                quantity = mintLimit - firstId;
            }
            // Unchecked arithmetic: alreadyMinted + quantity is less than 2 * walletLimit
            if (alreadyMinted + quantity > walletLimit) {
                // Reduce quantity to the remaining wallet allowance
                // Unchecked arithmetic: already checked that firstId is less than mintLimit
                quantity = walletLimit - alreadyMinted;
            }

            // Unchecked arithmetic: mintCount cannot exceed walletLimit
            mintCount[msg.sender] = alreadyMinted + quantity;
            // Unchecked arithmetic: can't exceed total existing wei; not expected to exceed walletLimit * startPrice
            mintPayment[msg.sender] += payment;
        }

        if (price < lowestPrice) {
            lowestPrice = price;
        }

        unchecked {
            for (uint256 i = 0; i < quantity; i++) {
                emit Purchase(msg.sender, firstId + i, price);
            }
        }

        // INTERACTIONS: call mint on known contract (tokenContract.mint contains no external interactions)
        tokenContract.mintBatch(msg.sender, quantity);
    }

    /// @notice Mint multiple tokens for the contract owner. Must pay at least `currentPrice` * `quantity`.
    /// @param quantity The number of tokens to mint
    function mintMultipleAbsentee(uint256 quantity) public payable virtual started whenNotPaused onlyOwner {
        // CHECKS state and inputs
        uint firstId = tokenContract.totalSupply();
        if (firstId >= mintLimit) revert SoldOut();
        require(quantity > 0, "Must mint at least one token");

        uint256 payment = msg.value;
        uint256 price = payment / quantity;
        require(price >= currentPrice(), "Insufficient payment");

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: firstId + quantity is less than mintLimit + walletLimit
            if (firstId + quantity > mintLimit) {
                // Reduce quantity to the remaining supply
                // Unchecked arithmetic: already checked that firstId is less than mintLimit
                quantity = mintLimit - firstId;
            }

            // Unchecked arithmetic: mintCount cannot exceed mintLimit
            mintCount[msg.sender] += quantity;
            // Unchecked arithmetic: can't exceed total existing wei; not expected to exceed walletLimit * startPrice
            mintPayment[msg.sender] += payment;
        }

        if (price < lowestPrice) {
            lowestPrice = price;
        }

        unchecked {
            for (uint256 i = 0; i < quantity; i++) {
                emit Purchase(msg.sender, firstId + i, price);
            }
        }

        // INTERACTIONS: call mint on known contract (tokenContract.mint contains no external interactions)
        tokenContract.mintBatch(msg.sender, quantity);
    }

    /// @notice Send any available refund to the message sender
    function refund() external returns (uint256) {
        // CHECK available refund
        uint256 refundAmount = refundAvailable(msg.sender);
        require(refundAmount > 0, "No refund available");

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: refundAmount will always be less than mintPayment
            mintPayment[msg.sender] -= refundAmount;
        }

        emit Refund(msg.sender, refundAmount);

        // INTERACTIONS
        (bool refunded, ) = msg.sender.call{value: refundAmount}("");
        require(refunded, "Refund transfer was reverted");

        return refundAmount;
    }

    // OWNER AND ADMIN FUNCTIONS

    /// @notice Mint reserve tokens to the designated `recipient`
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function reserve(address recipient, uint256 quantity) external unstarted onlyOwner {
        // CHECKS contract state
        uint totalCount = tokenContract.totalSupply();
        if (totalCount + quantity > mintLimit) revert SoldOut();

        // EFFECTS
        unchecked {
            // Unchecked arithmetic: neither value can exceed mintLimit
            reserveCount += quantity;
        }

        emit Reservation(recipient, quantity, reserveCount);

        // INTERACTIONS
        tokenContract.mintBatch(recipient, quantity);
    }

    /// @notice withdraw auction proceeds
    /// @dev Can only be called by the contract `owner` or a payee. Reverts if the final price is unknown or all
    ///  proceeds have already been withdrawn.
    function withdraw() external onlyPayee {
        // CHECKS contract state
        uint totalCount = tokenContract.totalSupply();
        bool soldOut = totalCount >= mintLimit;
        uint256 finalPrice = lowestPrice;
        if (!soldOut) {
            // Only allow a withdraw before the auction is sold out if the price has finished falling
            require(currentPrice() == restPrice, "Price is still falling");
            finalPrice = restPrice;
        }

        uint256 totalPayment = (totalCount - reserveCount) * finalPrice;
        require(totalPayment > previousPayment, "All funds have been withdrawn");

        // EFFECTS
        uint256 outstandingPayment = totalPayment - previousPayment;
        uint256 balance = address(this).balance;
        if (outstandingPayment > balance) {
            // Escape hatch to prevent stuck funds, but this shouldn't happen
            require(balance > 0, "All funds have been withdrawn");
            outstandingPayment = balance;
        }

        previousPayment += outstandingPayment;
        withdraw(outstandingPayment);
    }

    /// @notice Update the tokenContract contract address
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function setMintable(Mintable tokenContract_) external unstarted onlyOwner {
        // CHECKS inputs
        require(address(tokenContract_) != address(0), "Token contract must not be the zero address");
        // EFFECTS
        tokenContract = tokenContract_;
    }

    /// @notice Update the auction price range and rate of decrease
    /// @dev Since the values are validated against each other, they are all set together. Can only be called by the
    ///  contract `owner`. Reverts if the auction has already started.
    function setPriceRange(uint256 startPrice_, uint256 restPrice_, uint256 priceDrop) external unstarted onlyOwner {
        // CHECKS inputs
        require(startPrice_ > 1e15, "Start price too low: check that prices are in wei");
        require(restPrice_ > 1e15, "Rest price too low: check that prices are in wei");
        require(startPrice_ >= restPrice_, "Start price must not be lower than rest price");

        uint256 priceDifference;
        unchecked {
            priceDifference = startPrice_ - restPrice_;
        }
        require(priceDrop * 25 <= priceDifference, "Auction must last at least 5 minutes");
        require(priceDrop * (5 * 60 * 24) >= priceDifference, "Auction must not last longer than 24 hours");

        // EFFECTS
        startPrice = startPrice_;
        restPrice = restPrice_;
        priceDropPerSlot = priceDrop;
    }

    // VIEW FUNCTIONS

    /// @notice Query the current price
    function currentPrice() public view returns (uint256) {
        uint256 time = timeElapsed();
        unchecked {
            uint256 drop = priceDropPerSlot * (time / 12);
            if (startPrice < restPrice + drop) return restPrice;
            return startPrice - drop;
        }
    }

    /// @notice Query the refund available for the specified `minter`
    function refundAvailable(address minter) public view returns (uint256) {
        uint256 minted = mintCount[minter];
        if (minted == 0) return 0;

        uint totalCount = tokenContract.totalSupply();
        bool soldOut = totalCount >= mintLimit;
        uint256 refundPrice = soldOut ? lowestPrice : currentPrice();

        uint256 payment = mintPayment[minter];
        uint256 newPayment;
        uint256 refundAmount;
        unchecked {
            // Unchecked arithmetic: newPayment cannot exceed walletLimit * startPrice
            newPayment = minted * refundPrice;
            // Unchecked arithmetic: value only used if newPayment < payment
            refundAmount = payment - newPayment;
        }

        return (newPayment < payment) ? refundAmount : 0;
    }
}
