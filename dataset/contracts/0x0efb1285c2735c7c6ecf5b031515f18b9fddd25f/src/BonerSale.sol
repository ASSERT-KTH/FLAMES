pragma solidity ^0.8.7;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract BonerSale is Ownable {
    struct Contribution {
        address addr;
        uint256 amount;
    }

    IERC20 public immutable boner;
    address public constant DEPLOYER =
        0x76D1E54a65d8E786511809FBDc2c663264383952;
    uint256 public constant MIN_CONTRIBUTION = .05 ether;
    uint256 public constant MAX_CONTRIBUTION = 5 ether;
    uint256 public constant MAX_SUPPLY = 1_000_000_000_000e18;
    uint256 public constant PRESALE_SUPPLY = 700_000_000_000e18;
    bool public open;
    uint256 public totalContributed;
    uint256 public numContributors;
    mapping(uint256 => Contribution) public contribution;
    mapping(address => uint256) public contributor;

    constructor(IERC20 boner_) {
        boner = boner_;
    }

    /**
     * @notice Min 0.05 ether required
     */
    function purchase() public payable {
        require(open, "Not Open");
        uint256 currentContribution = contribution[contributor[msg.sender]]
            .amount;
        // contribution limits
        require(msg.value >= MIN_CONTRIBUTION, "Below Minimum Contribution");
        require(
            msg.value + currentContribution <= MAX_CONTRIBUTION,
            "Above Maximum Contribution"
        );
        // find or create the contributor
        uint256 contributionIndex;
        if (contributor[msg.sender] != 0) {
            contributionIndex = contributor[msg.sender];
        } else {
            contributionIndex = numContributors + 1;
            numContributors++;
        }
        contributor[msg.sender] = contributionIndex;
        contribution[contributionIndex].addr = msg.sender;
        contribution[contributionIndex].amount += msg.value;
        totalContributed += msg.value;
    }

    function airdrop() external onlyOwner {
        uint256 pricePerToken = (totalContributed * 10e18) / PRESALE_SUPPLY;
        for (uint256 i = 1; i <= numContributors; i++) {
            uint256 contributionAmount = contribution[i].amount * 10e18;
            uint256 numberOfTokensToMint = contributionAmount / pricePerToken;
            boner.transfer(contribution[i].addr, numberOfTokensToMint);
        }
    }

    function toggle() external onlyOwner {
        open = !open;
    }

    function refund() external onlyOwner {
        for (uint256 i = 1; i <= numContributors; i++) {
            address payable refundAddress = payable(contribution[i].addr);
            refundAddress.transfer(contribution[i].amount);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(DEPLOYER).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw failed");
    }

    function withdrawERC20() external onlyOwner {
        uint256 balance = boner.balanceOf(address(this));
        if (balance > 0) {
            boner.transfer(DEPLOYER, balance);
        }
    }
}
