// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface ERC20 {

    function _maxWalletSize() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}



contract AirdropContractV2 {

    
    using SafeMath for uint256;
    address public deployer;
    address public enqAdmin;
    address public lushAddress;
    mapping(address => uint256) public airdropAllocation;
    bool isActive;
    bool isContributionOpen;

    uint public marketCap = 400 * 10**18;// 400 ETH initial market cap
    uint public totalETHContribution;
    uint public thisRoundETHContribution;
    

    constructor(address _enqAdmin) payable {
        deployer = msg.sender;
        enqAdmin = _enqAdmin;
    }

    /// @notice User calls this function to claim airdrop
    function claimAirdrop() external{
        require(isActive  == true, "Not active yet");
        uint256 yourAirdropAlloc = airdropAllocation[msg.sender];
        require(yourAirdropAlloc  > 0, "Nothing to claim");


        airdropAllocation[msg.sender] = 0;
        ERC20(lushAddress).transfer(msg.sender, yourAirdropAlloc);
    }

    function contribute() external payable{
        require(isContributionOpen  == true, "Contribution not open");
        uint contributionAmount = msg.value;
        uint lushAmount = contributionAmount.mul(ERC20(lushAddress).totalSupply()).div(marketCap);
        uint totalWalletAmount = lushAmount + ERC20(lushAddress).balanceOf(msg.sender);

        uint maxThreshold = 150000000 * 10**18;
        require(totalWalletAmount <  maxThreshold, "Reached Max Wallet Threshold");

        thisRoundETHContribution = thisRoundETHContribution.add(contributionAmount);
        require(thisRoundETHContribution <= marketCap.div(20), "No more allocation");
        ERC20(lushAddress).transfer(msg.sender, lushAmount);
    }



//////////////////////////////////////////////////////////Admin Functions////////////////////////////////////////////////

    /// @notice Upload EnqAI wallet balances
    /// @notice Can split entire list of holders and call this function multiple times (since holder count is large)
    /// @param walletAddresses Array of wallets
    /// @param walletAmounts EnqAI balances corresponding to each wallet - MAKE SURE THIS DATA IS IN THE SAME ORDER AS walletAddresses
    function uploadEnqHolderData(address[] memory walletAddresses, uint256[] memory walletAmounts) external{
        require(msg.sender  == enqAdmin, "No permission");
        require(isActive  == false, "Can only upload balances prior to start of activation");


        for (uint8 i = 0; i < walletAddresses.length; i++) {
            airdropAllocation[walletAddresses[i]] = walletAmounts[i];
        }
    }


    /// @notice Execute this function after finished calling uploadEnqHolderData
    function activateAirdrop(address _lushAddress) external{
        require(msg.sender  == deployer, "No permission");
        isActive = true;
        isContributionOpen = true;
        lushAddress = _lushAddress;
    }

    function renewContribution(uint _newMarketCap) external{
        require(msg.sender  == deployer, "No permission");
        require(_newMarketCap  > marketCap, "New market cap should be larger");
        uint thisRoundContributed = thisRoundETHContribution;
        totalETHContribution = totalETHContribution + thisRoundContributed;
        thisRoundETHContribution = 0;
        marketCap = _newMarketCap;
    }

    function updateIsContributionOpen(bool _isOpen) external {
        require(msg.sender  == deployer, "No permission");
        isContributionOpen = _isOpen;
    }

    function extractETH() external {
        require(msg.sender  == deployer, "No permission");
        if(address(this).balance > 0){
            payable(deployer).transfer(address(this).balance);
        }
    }
    function extractRemainingLush() external {
        require(msg.sender  == deployer, "No permission");
        uint256 lushContractBalance = ERC20(lushAddress).balanceOf(address(this));
        ERC20(lushAddress).transfer(deployer, lushContractBalance);
    }   


    receive() external payable {

    }
}