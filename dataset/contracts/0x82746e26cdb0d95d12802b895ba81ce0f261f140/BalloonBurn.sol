// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IManifoldERC1155.sol";
import "./IBurnExtension.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BalloonBurn is Ownable {
    IManifoldERC1155 public balloonContract =
        IManifoldERC1155(0x1386f70A946Cf9F06E32190cFB2F4F4f18365b87);
    IBurnExtension public balloonBurn = IBurnExtension(0xfa1B15dF09c2944a91A2F9F10A6133090d4119BD);

    uint256 pinkBurnIndex = 561955056;
    uint256 blackBurnIndex = 547537136;
    uint256 blueBurnIndex = 547496176;
    uint256 greenBurnIndex = 547492080;

    uint256 public ticketTokenId = 2;
    uint256 public pinkBalloonTokenId = 3;
    uint256 public blackBalloonTokenId = 4;
    uint256 public blueBalloonTokenId = 5;
    uint256 public greenBalloonTokenId = 6;

    uint256[] public ticketTokenIds;

    bool public enabled;

    constructor() {
        enabled = false;

        ticketTokenIds = new uint256[](1);
        ticketTokenIds[0] = ticketTokenId;
    }

    event BalloonMint(
        address indexed user,
        uint32 pinkBalloons,
        uint32 blackBalloons,
        uint32 blueBalloons,
        uint32 greenBalloons
    );

    function burnAndMint(
        uint32 pinkBalloons,
        uint32 blackBalloons,
        uint32 blueBalloons,
        uint32 greenBalloons
    ) external {
        require(enabled, "BalloonBurn: Contract is not enabled");
        require(
            pinkBalloons + blackBalloons + blueBalloons + greenBalloons > 0,
            "BalloonBurn: You must burn at least one ticket"
        );

        uint256[] memory ticketAmounts = new uint256[](1);
        ticketAmounts[0] = pinkBalloons + blackBalloons + blueBalloons + greenBalloons;
        balloonContract.burn(msg.sender, ticketTokenIds, ticketAmounts);

        address[] memory addresses = new address[](1);
        addresses[0] = msg.sender;
        if (pinkBalloons > 0) {
            uint32[] memory pinkBalloonsArr = new uint32[](1);
            pinkBalloonsArr[0] = pinkBalloons;
            balloonBurn.airdrop(
                address(balloonContract),
                pinkBurnIndex,
                addresses,
                pinkBalloonsArr
            );
        }
        if (blackBalloons > 0) {
            uint32[] memory blackBalloonsArr = new uint32[](1);
            blackBalloonsArr[0] = blackBalloons;
            balloonBurn.airdrop(
                address(balloonContract),
                blackBurnIndex,
                addresses,
                blackBalloonsArr
            );
        }
        if (blueBalloons > 0) {
            uint32[] memory blueBalloonsArr = new uint32[](1);
            blueBalloonsArr[0] = blueBalloons;
            balloonBurn.airdrop(
                address(balloonContract),
                blueBurnIndex,
                addresses,
                blueBalloonsArr
            );
        }
        if (greenBalloons > 0) {
            uint32[] memory greenBalloonsArr = new uint32[](1);
            greenBalloonsArr[0] = greenBalloons;
            balloonBurn.airdrop(
                address(balloonContract),
                greenBurnIndex,
                addresses,
                greenBalloonsArr
            );
        }

        emit BalloonMint(msg.sender, pinkBalloons, blackBalloons, blueBalloons, greenBalloons);
    }

    function setEnabled(bool newState) external onlyOwner {
        enabled = newState;
    }

    function getInfo(
        address user
    )
        public
        view
        returns (
            uint256 ticketAmount,
            uint256 balance,
            bool hasApproved,
            bool isEnabled,
            uint256 pinkBalloonAmount,
            uint256 blackBalloonAmount,
            uint256 blueBalloonAmount,
            uint256 greenBalloonAmount,
            uint256 pinkBalloonTotalAmount,
            uint256 blackBalloonTotalAmount,
            uint256 blueBalloonTotalAmount,
            uint256 greenBalloonTotalAmount
        )
    {
        if (user == address(0)) {
            ticketAmount = 0;
            hasApproved = false;
            balance = 0;

            pinkBalloonAmount = 0;
            blackBalloonAmount = 0;
            blueBalloonAmount = 0;
            greenBalloonAmount = 0;
        } else {
            ticketAmount = balloonContract.balanceOf(user, ticketTokenId);
            hasApproved = balloonContract.isApprovedForAll(user, address(this));
            balance = payable(user).balance;

            pinkBalloonAmount = balloonContract.balanceOf(user, pinkBalloonTokenId);
            blackBalloonAmount = balloonContract.balanceOf(user, blackBalloonTokenId);
            blueBalloonAmount = balloonContract.balanceOf(user, blueBalloonTokenId);
            greenBalloonAmount = balloonContract.balanceOf(user, greenBalloonTokenId);
        }

        isEnabled = enabled;

        pinkBalloonTotalAmount = balloonContract.totalSupply(pinkBalloonTokenId);
        blackBalloonTotalAmount = balloonContract.totalSupply(blackBalloonTokenId);
        blueBalloonTotalAmount = balloonContract.totalSupply(blueBalloonTokenId);
        greenBalloonTotalAmount = balloonContract.totalSupply(greenBalloonTokenId);
    }
}
