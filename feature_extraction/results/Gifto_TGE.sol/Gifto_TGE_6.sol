// File: ../sc_datasets/DAppSCAN/Blockchain Labs NZ-Gifto/GiftoSmartContract-50e1f1895dd91a0dad0d4f0b2ea620e5827ed1fa/Gifto_TGE.sol
pragma solidity ^0.4.18;
// ----------------------------------------------------------------------------------------------
// Gifto Token by Gifto Limited.
// An ERC20 standard
//
// author: Gifto Team
// Contact: datwhnguyen@gmail.com
contract ERC20Interface {
    // Get the total token supply
    function totalSupply() public constant returns (uint256 _totalSupply);
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);
    // transfer _value amount of token approved by address _from
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    // approve an address with _value amount of tokens
    function approve(address _spender, uint _value) public returns (bool success);
    // get remaining token approved by _owner to _spender
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract Gifto is ERC20Interface {
    uint public constant decimals = 5;
    string public constant symbol = "Gifto";
    string public constant name = "Gifto";
    bool public _selling = false;//initial not selling
    uint public _totalSupply = 10 ** 14; // total supply is 10^14 unit, equivalent to 10^9 Gifto
    uint public _originalBuyPrice = 45 * 10**7; // original buy 1ETH = 3000 Gifto = 3 * 10**8 unit
    // Owner of this contract
    address public owner;
    // Balances Gifto for each account
    mapping(address => uint256) balances;
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
    // List of approved investors
    mapping(address => bool) approvedInvestorList;
    // mapping Deposit
    mapping(address => uint256) deposit;
    // buyers buy token deposit
    address[] buyers;
    // icoPercent
    uint _icoPercent = 10;
    // _icoSupply is the avalable unit. Initially, it is _totalSupply
    uint public _icoSupply = _totalSupply * _icoPercent / 100;
    // SWC-Presence of unused variables: L71 - L72
    // minimum buy 0.3 ETH
    uint public _minimumBuy = 3 * 10 ** 17;
    // maximum buy 30 ETH
    uint public _maximumBuy = 30 * 10 ** 18;
    /**
     * Functions with this modifier can only be executed by the owner
     */
    modifier onlyOwner() {
    }
    /**
     * Functions with this modifier can only be executed by users except owners
     */
    modifier onlyNotOwner() {
    }
    /**
     * Functions with this modifier check on sale status
     * Only allow sale if _selling is on
     */
    modifier onSale() {
    }
    /**
     * Functions with this modifier check the validity of address is investor
     */
    modifier validInvestor() {
    }
    /**
     * Functions with this modifier check the validity of msg value
     * value must greater than equal minimumBuyPrice
     * total deposit must less than equal maximumBuyPrice
     */
    // SWC-Presence of unused variables: L116 - L121
    modifier validValue(){
    }
    /**
     * Functions with this modifier check the validity of range [a, b] <= [0, buyers.length-1]
     */
    modifier validRange(uint a, uint b){
    }
    /// @dev Fallback function allows to buy ether.
    function()
        public
        payable {
    }
    /// @dev buy function allows to buy ether. for using optional data
    function buyGifto()
        public
        payable
        onSale
        validValue
        validInvestor {
    }
    /// @dev Constructor
    function Gifto() 
        public {
    }
    /// @dev Gets totalSupply
    /// @return Total supply
    function totalSupply()
        public 
        constant 
        returns (uint256) {
    }
    /// @dev Enables sale 
    function turnOnSale() onlyOwner 
        public {
    }
    /// @dev Disables sale
    function turnOffSale() onlyOwner 
        public {
    }
    /// @dev set new icoPercent
    /// @param newIcoPercent new value of icoPercent
    function setIcoPercent(uint256 newIcoPercent)
        public 
        onlyOwner {
    }
    /// @dev set new _maximumBuy
    /// @param newMaximumBuy new value of _maximumBuy
    function setMaximumBuy(uint256 newMaximumBuy)
        public 
        onlyOwner {
    }
    /// @dev Updates buy price (owner ONLY)
    /// @param newBuyPrice New buy price (in unit)
    function setBuyPrice(uint newBuyPrice) 
        onlyOwner 
        public {
        require(<FILL_ME>);
        _originalBuyPrice = newBuyPrice;
        // control _maximumBuy is 10,000 USD, Gifto price is 0.1USD
        // proposed: 1 ETH = 300USD => 1 ETH = 3000 Gifto = _originalBuyPrice,
        // _maximumBuy = 10,000 / 300 = 100,000 / _originalBuyPrice ~ 33 ETH
        _maximumBuy = 100000 * 10**18 /_originalBuyPrice;
    }
    /// @dev Gets account's balance
    /// @param _addr Address of the account
    /// @return Account balance
    function balanceOf(address _addr) 
        public
        constant 
        returns (uint256) {
    }
    /// @dev check address is approved investor
    /// @param _addr address
    function isApprovedInvestor(address _addr)
        public
        constant
        returns (bool) {
    }
    /// @dev get investors deposited
    function getBuyers()
    public
    constant
    returns(address[]){
    }
    /// @dev get ETH deposit
    /// @param _addr address get deposit
    /// @return amount deposit of an buyer
    function getDeposit(address _addr)
        public
        constant
        returns(uint256){
    }
    /// @dev Adds list of new investors to the investors list and approve all
    /// @param newInvestorList Array of new investors addresses to be added
    function addInvestorList(address[] newInvestorList)
        onlyOwner
        public {
    }
    /// @dev Removes list of investors from list
    /// @param investorList Array of addresses of investors to be removed
    function removeInvestorList(address[] investorList)
        onlyOwner
        public {
    }
    /// @dev delivery token for buyer
    /// @param a start point
    /// @param b end point
    function deliveryToken(uint a, uint b)
        public
        onlyOwner
        validRange(a, b) {
    }
    /// @dev Transfers the balance from Multisig wallet to an account
    /// @param _to Recipient address
    /// @param _amount Transfered amount in unit
    /// @return Transfer status
    function transfer(address _to, uint256 _amount)
        public 
        returns (bool) {
    }
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
    public
    returns (bool success) {
    }
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) 
        public
        returns (bool success) {
    }
    // get allowance
    function allowance(address _owner, address _spender) 
        public
        constant 
        returns (uint256 remaining) {
    }
    /// @dev Withdraws Ether in contract (Owner only)
    /// @return Status of withdrawal
    function withdraw() onlyOwner 
        public 
        returns (bool) {
    }
}
/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <stefan.george@consensys.net>
contract MultiSigWallet {
    uint constant public MAX_OWNER_COUNT = 50;
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
    event CoinCreation(address coin);
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;
    bool flag = true;
    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }
    modifier onlyWallet() {
    }
    modifier ownerDoesNotExist(address owner) {
    }
    modifier ownerExists(address owner) {
    }
    modifier transactionExists(uint transactionId) {
    }
    modifier confirmed(uint transactionId, address owner) {
    }
    modifier notConfirmed(uint transactionId, address owner) {
    }
    modifier notExecuted(uint transactionId) {
    }
    modifier notNull(address _address) {
    }
    modifier validRequirement(uint ownerCount, uint _required) {
    }
    /// @dev Fallback function allows to deposit ether.
    function()
        payable
    {
    }
    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function MultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
    }
    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
    }
    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
    }
    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param owner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
    }
    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
    }
    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
    }
    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
    }
    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
    }
    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
    }
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
    }
    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
    }
    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
    }
    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
    }
    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
    }
    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
    }
    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
    }
    /// @dev Create new coin.
    function createCoin()
        external
        onlyWallet
    {
    }
}