/*
//Twitter: https://twitter.com/HungerBotETH
//Telegram: https://t.me/HungerPortal
//Website: https://hungerboteth.com/
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./HungerBot.sol";

/**
 * @title EscrowGameContract
 * @dev A smart contract for playing an Hunger  game on Telegram with Hunger token bets.
 */
contract HungerGameEscrow is Ownable {
    HungerBot public token;

    struct EscrowGame {
        bool ongoing;
        uint256 totalWager;
    }

    using SafeMath for uint256;

    mapping(uint256 => EscrowGame) public games;
    address public taxReceiver;
    uint256 public taxPercentage;
    uint256 public burnPercentage;

    event WagerPlaced(
        uint256 indexed gameIdentifier,
        address[] indexed participants,
        uint256 totalWager
    );
    event WinnerRewarded(
        uint256 indexed gameIdentifier,
        address indexed victor,
        uint256 prizeAmount
    );

    constructor(
        HungerBot _tokenAddress,
        address _taxReceiver,
        uint256 _taxPercentage,
        uint256 _burnPercentage
    ) {
        token = HungerBot(_tokenAddress);
        taxReceiver = _taxReceiver;
        taxPercentage = _taxPercentage;
        burnPercentage = _burnPercentage;
    }

    address[] internal players;

    /**
     * @dev Check if there is an ongoing game for a Telegram group.
     * @param _gameIdentifier Telegram group to check
     * @return true if there is an ongoing game, otherwise false
     */
    function isGameOngoing(uint256 _gameIdentifier) public view returns (bool) {
        return games[_gameIdentifier].ongoing;
    }

    /**
     * @dev Place wagers for a new game.
     * @param gameIdentifier Identifier for the game
     * @param _participants Array of participant addresses
     * @param wagers Array of wager amounts corresponding to participants
     * @return true if wagers are successfully placed
     */
    function postBets(
        uint256 gameIdentifier,
        address[] memory _participants,
        uint256[] memory wagers
    ) external onlyOwner returns (bool) {
        require(
            _participants.length > 1,
            "EscrowGame: Must involve more than 1 participant"
        );
        require(
            _participants.length == wagers.length,
            "EscrowGame: Participant count must match wager count"
        );
        require(
            areAllWagersEqual(wagers),
            "EscrowGame: All wager amounts must be equal"
        );

        uint256 totalWagered = 0;
        for (uint256 i = 0; i < _participants.length; i++) {
            require(
                token.allowance(_participants[i], address(this)) >= wagers[i],
                "EscrowGame: Insufficient allowance"
            );
            players.push(_participants[i]);
            token.transferFrom(_participants[i], address(this), wagers[i]);
            totalWagered += wagers[i];
        }
        games[gameIdentifier] = EscrowGame(true, totalWagered);

        emit WagerPlaced(gameIdentifier, players, totalWagered);
        return true;
    }

    /**
     * @dev Reward the winner of a game and distribute taxes.
     * @param _gameIdentifier Identifier for the game
     * @param _victor Address of the winner
     */
    function payOut(
        uint256 _gameIdentifier,
        address _victor
    ) external onlyOwner {
        require(
            isGameOngoing(_gameIdentifier),
            "EscrowGame: Invalid Game Identifier"
        );
        require(
            isParticipantInArray(_victor),
            "EscrowGame: Invalid Winner Address"
        );

        EscrowGame storage g = games[_gameIdentifier];
        uint256 taxAmount = g.totalWager.mul(taxPercentage).div(100);
        uint256 burnShare = g.totalWager.mul(burnPercentage).div(100);
        uint256 prizeAmount = g.totalWager.sub(taxAmount).sub(burnShare);
        require(
            taxAmount + prizeAmount + burnShare <= g.totalWager,
            "EscrowGame: Transfer Amount Exceeds Total Share"
        );

        token.transfer(_victor, prizeAmount);
        token.transfer(taxReceiver, taxAmount);
        token.burn(burnShare);
        delete games[_gameIdentifier];
        delete players;

        emit WinnerRewarded(_gameIdentifier, _victor, prizeAmount);
    }

    /**
     * @dev Set the address for tax collection.
     * @param _taxReceiver Address to receive taxes
     */
    function setTaxReceiver(address _taxReceiver) public onlyOwner {
        taxReceiver = _taxReceiver;
    }

    /**
     * @dev Set the tax percentage.
     * @param _taxPercentage New tax percentage
     */
    function setTaxPercentage(uint256 _taxPercentage) public onlyOwner {
        taxPercentage = _taxPercentage;
    }

    /**
     * @dev Check if a participant address is in the participants array.
     * @param _participant Address to check
     * @return true if the participant is in the array, otherwise false
     */
    function isParticipantInArray(
        address _participant
    ) private view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == _participant) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Check if all wager amounts in an array are equal.
     * @param wagers Array of wager amounts
     * @return true if all wagers are equal, otherwise false
     */
    function areAllWagersEqual(
        uint256[] memory wagers
    ) private pure returns (bool) {
        if (wagers.length <= 1) {
            return true;
        }

        for (uint256 i = 1; i < wagers.length; i++) {
            if (wagers[i] != wagers[0]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Withdraw ETH balance from the contract.
     */
    function withdrawEther() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Withdraw ERC20 token balance from the contract.
     * @param _tokenAddress Address of the ERC20 token
     */
    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(msg.sender, balance);
    }

    function modifyTokenAddress(
        address payable _tokenAddress
    ) public onlyOwner {
        token = HungerBot(_tokenAddress);
    }
}
