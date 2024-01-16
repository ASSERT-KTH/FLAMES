// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Operator.sol";

//      |||||\          |||||\               |||||\           |||||\
//      ||||| |         ||||| |              ||||| |          ||||| |
//       \__|||||\  |||||\___\|               \__|||||\   |||||\___\|
//          ||||| | ||||| |                      ||||| |  ||||| |
//           \__|||||\___\|       Y u g a         \__|||||\___\|
//              ||||| |             L a b s          ||||| |
//          |||||\___\|                          |||||\___\|
//          ||||| |               J T M          ||||| |
//           \__|||||||||||\        B u f f s     \__|||||||||||\
//              ||||||||||| |                        ||||||||||| |
//               \_________\|                         \_________\|

error BuffPurchasesNotEnabled();

contract JimmyTheMonkeyBuffs is Operator {
    uint256 public buffCost;
    uint256 public buffTimeIncrease = 660;
    bool public buffPurchasesEnabled = false;
    address public immutable apeCoinContract;

    mapping(address => uint256) public playerAddressToBuffTimestamp;

    event BuffPurchased(
        address indexed playerAddress,
        uint256 indexed buffTimestamp
    );

    constructor(
        address _apeCoinContract,
        uint256 _buffCost,
        address _operator
    ) Operator(_operator) {
        apeCoinContract = _apeCoinContract;
        buffCost = _buffCost;
    }

    /**
     * @notice Purchase a buff boost - time starts when the transaction is confirmed
     */
    function purchaseBuff() external {
        if (!buffPurchasesEnabled) revert BuffPurchasesNotEnabled();

        uint256 currentBuffTimestamp = playerAddressToBuffTimestamp[msg.sender];
        uint256 newTimestamp;

        if (currentBuffTimestamp > block.timestamp) {
            newTimestamp = currentBuffTimestamp + buffTimeIncrease;
        } else {
            newTimestamp = block.timestamp + buffTimeIncrease;
        }

        IERC20(apeCoinContract).transferFrom(
            msg.sender,
            address(this),
            buffCost
        );

        emit BuffPurchased(msg.sender, newTimestamp);
        playerAddressToBuffTimestamp[msg.sender] = newTimestamp;
    }

    /**
     * @notice Get the ending boost timestamp for a player address
     * @param playerAddress the address of the player
     * @return uint256 unix timestamp
     */
    function getBuffTimestampForPlayer(
        address playerAddress
    ) external view returns (uint256) {
        return playerAddressToBuffTimestamp[playerAddress];
    }

    /**
     * @notice Get the seconds remaining in the boost for a player address
     * @param playerAddress the address of the player
     * @return uint256 seconds of boost remaining
     */
    function getRemainingBuffTimeInSeconds(
        address playerAddress
    ) external view returns (uint256) {
        uint256 currentBuffTimestamp = playerAddressToBuffTimestamp[
            playerAddress
        ];
        if (currentBuffTimestamp > block.timestamp) {
            return currentBuffTimestamp - block.timestamp;
        }
        return 0;
    }

    // Operator functions

    /**
     * @notice Set the cost of buff boost
     * @param _buffCost cost in wei
     */
    function setBuffCost(uint256 _buffCost) external onlyOperator {
        buffCost = _buffCost;
    }

    /**
     * @notice Change the buff time increase - this will never be used
     * @param _buffTimeIncrease time increase in seconds
     */
    function setBuffTimeIncrease(
        uint256 _buffTimeIncrease
    ) external onlyOperator {
        buffTimeIncrease = _buffTimeIncrease;
    }

    /**
     * @notice Toggle the purchased state of buffs
     */
    function flipBuffPurchasesEnabled() external onlyOperator {
        buffPurchasesEnabled = !buffPurchasesEnabled;
    }

    /**
     * @notice Withdraw erc-20 tokens
     * @param coinContract the erc-20 contract address
     */
    function withdraw(address coinContract) external onlyOperator {
        uint256 balance = IERC20(coinContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(coinContract).transfer(operator, balance);
        }
    }
}
