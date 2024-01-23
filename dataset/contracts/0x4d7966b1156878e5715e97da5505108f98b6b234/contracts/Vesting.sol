// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Vesting is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint public startUnlock;
    uint public endUnlock;
    uint public totalAmount;
    uint public alreadyReceivedAmount = 0;

    event Claimed(uint amount, uint when);

    function init(IERC20 _token, uint amount, uint _startUnlock, uint _endUnlock) external onlyOwner {
        require(block.timestamp < _startUnlock, "startUnlock is not in the future");
        require(_startUnlock < _endUnlock, "startUnlock >= endUnlock");
        require(address(token) == address(0), "Already initialized");
        token = _token;

        // lock sender's tokens in this contract
        token.safeTransferFrom(msg.sender, address(this), amount);

        startUnlock = _startUnlock;
        endUnlock = _endUnlock;
        totalAmount = amount;
    }

    function claim() external onlyOwner {
        require(block.timestamp >= startUnlock, "Claim is not yet available");
        uint amount = getAvailableToClaim();

        alreadyReceivedAmount += amount;
        token.safeTransfer(msg.sender, amount);
        emit Claimed(amount, block.timestamp);
    }

    /**
     * @notice Gets the amount of tokens currently available to claim.
     * Tokens become partially available after `startUnlock` timestamp. All tokens will be
     * available to claim after `endUnlock` timestamp.
     */
    function getAvailableToClaim() public view returns (uint) {
        if (block.timestamp < startUnlock) return 0;
        return
            (totalAmount * (Math.min(block.timestamp, endUnlock) - startUnlock)) /
            (endUnlock - startUnlock) -
            alreadyReceivedAmount;
    }
}
