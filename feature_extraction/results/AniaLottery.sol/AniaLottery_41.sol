// SPDX-License-Identifier: MIT
// SWC-Outdated Compiler Version: L3
// SWC-Floating Pragma: L8
pragma solidity ^0.8.2;
import "./AniaStake.sol";
contract AniaLottery {
    AniaStake public tokenStaking;
    address public owner;
    uint public tierOne = 50000;
    uint public tierOneTicketValue = 1000;
    uint public tierTwo = 20000;
    uint public tierTwoTicketValue = 500;
    uint public tierThree = 10000;
    uint public tierThreeTicketValue = 250;
    uint internal decimals = 1000000000000000000;
    event eventAddUserToWhitelist(uint indexed id, address user, uint signupDate);
    event eventAddUserToLotteryWinners(uint indexed id, address user, uint reward, uint claimed);
    struct Project {
        uint id;
        string name;
        uint raiseGoal;
        uint endDate;
        address contractAddress;
        address billingAddress;
        uint firstPayoutInPercent;
        uint256 tokenPrice;
        bool draw;
    }
    mapping (uint => Project) projects;
    struct Whitelist {
        uint projectId;
        uint signupDate;
        address userAddress;
    }
    struct LotteryWinner {
        uint projectId;
        address userAddress;
        uint reward;
        bool claimed;
    }
    constructor(AniaStake _tokenStaking) {
    }
    modifier onlyAdmin {
    }
    modifier onlyOwner {
    }
    mapping(uint => uint) projectUserCount;
    mapping(uint => Whitelist[]) projectsWhitelist;
    mapping(uint => mapping(address => uint256)) projectUserIndex;
    mapping(uint => uint) projectStakeCap;
    mapping(uint => uint) lotteryWinnerCount;
    mapping(uint => LotteryWinner[]) lotteryWinners;
    mapping(uint => mapping(address => uint256)) projectWinnerIndex;
    mapping(uint => uint) projectRaisedAmount;
    mapping (address => bool) admins;
    mapping (address => bool) stableCoins;
    // ADMIN
    function setAdmin(address _admin, bool isAdmin) public onlyOwner {
    }
    function removeAdmin(address adminAddress) public onlyAdmin {
    }
    function setStableCoin(address _address, bool isActive) public onlyOwner {
    }
    function createProject(uint projectId, string calldata projectName, uint raiseGoal, uint endDate, address contractAddress, address billingAddress, uint firstPayoutInPercent, uint256 tokenPrice) external onlyAdmin {
    }
    function updateProject(uint projectId, string calldata projectName, uint raiseGoal, uint endDate, address contractAddress, address billingAddress, uint firstPayoutInPercent, uint256 tokenPrice) external onlyAdmin {
    }
    function removeProject(uint projectId) external onlyAdmin {
    }
    // If there are any resources, the owner can withdraw them
    // SWC-Unprotected Ether Withdrawal: L117 - L119
    function withdraw() public payable onlyOwner {
    }
    function withdrawTokens(uint projectId, address recipient) public onlyAdmin {
    }
    // Add users to the whitelist in bulk
    function addUsersToWhitelist(uint projectId, address[] calldata users, bool checkEndDate) external onlyAdmin {
    }
    // Bulk removal of users from the whitelist
    function removeUsersFromWhitelist(uint projectId, address[] calldata users) external onlyAdmin {
    }
    function getUserTicketValue(address _address) public view returns (uint256) {
    }
    function getProjectStakeCap(uint projectId) public view returns(uint256) {
    }
    function getProjectRaisedAmount(uint projectId) public view returns(uint256) {
    }
    function lotteryDraw(uint projectId, address[] calldata users) external onlyAdmin {
    }
    function getProject(uint projectId) external view returns (Project memory) {
    }
    function getUserCount(uint projectId) external view returns (uint) {
    }
    function getProjectUser(uint projectId, address userAddress) public view returns (Whitelist memory) {
    }
    function getLotteryWinner(uint projectId, address userAddress) public view returns (LotteryWinner memory) {
    }
    function getLotteryWinnerCount(uint projectId) external view returns (uint) {
    }
    function setLotteryWinnerClaimedStatus(uint projectId, address userAddress) internal {
    }
    // Helper functions
    function changeTierOne(uint _value) external onlyAdmin {
    }
    function changeTierTwo(uint _value) external onlyAdmin {
    }
    function changeTierThree(uint _value) external onlyAdmin {
    }
    function changeTierOneTicketValue(uint _value) external onlyAdmin {
    }
    function changeTierTwoTicketValue(uint _value) external onlyAdmin {
    }
    function changeTierThreeTicketValue(uint _value) external onlyAdmin {
    }
    // USER
    function signUpToWhitelist(uint projectId) external {
    }
    function logoutFromWhitelist(uint projectId) external {
    }
    // We will check if the whitelisting is open
    function isProjectOpen(uint projectId) external view returns (bool){
    }
    // We will check if the user exists in the list
    function isUserInWhitelist(uint projectId) external view returns (bool) {
    }
    function checkBuy(uint projectId, uint256 tokensToBuy) public view returns (bool) {
    }
    function buy(uint projectId, uint pay, address tokenForPayContractAddress) external {
        require(stableCoins[tokenForPayContractAddress], "This Token is not available for payment");
        // Payment must be greater than 0
        require(pay > 0, "You need to send some ether");
        require(getUserTicketValue(msg.sender) == pay, "You need to pay the exact tier value before claiming the reward");
        uint256 tokensToBuy = decimals * (pay * decimals) / projects[projectId].tokenPrice * projects[projectId].firstPayoutInPercent / 100;
        // Check requirements before any transactions
        checkBuy(projectId, tokensToBuy);
        address billingAddress = projects[projectId].billingAddress;
        address contractAddress = projects[projectId].contractAddress;
        require(<FILL_ME>);
        // Create a token from a given contract address
        IERC20 token = IERC20(contractAddress);
        // I will transfer a certain number of tokens to the payer. Not all
        token.transfer(msg.sender, tokensToBuy);
        // Transfer stable Coin to Token owner
        IERC20 stableCoin = IERC20(tokenForPayContractAddress);
        stableCoin.transferFrom(msg.sender, billingAddress, pay * decimals);
        // Set the claimed attribute to true to avoid repeatedly withdrawn
        setLotteryWinnerClaimedStatus(projectId, msg.sender);
        projectRaisedAmount[projectId] += pay;
    }
    // Check the balance for a specific token for a specific address
    function anyoneTokenBalance(address tokenContractAddress, address userAddress) public view returns(uint) {
    }
    // Internal functions
    function _checkProjectExistById(uint projectId) internal view returns (bool) {
    }
    function _checkUserExistInProject(uint projectId, address userAddress) internal view returns (bool) {
    }
    function _checkUserIsProjectWinner(uint projectId, address userAddress) internal view returns (bool) {
    }
    function _checkOpenProject(uint projectId) internal view returns (bool) {
    }
    function _removeUserFromProject(uint256 projectId, address userAddress) internal {
    }
    function _removeAdminFromAdmins(address adminAddress) internal {
    }
    function _removeWhitelist(uint projectId) internal {
    }
    function _removeProject(uint projectId) internal {
    }
}