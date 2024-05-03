pragma solidity ^0.5.8;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    }
}
contract AccountFrozenBalances {
    using SafeMath for uint256;
    mapping (address => uint256) private frozen_balances;
    function _frozen_add(address _account, uint256 _amount) internal returns (bool) {
    }
    function _frozen_sub(address _account, uint256 _amount) internal returns (bool) {
    }
    function _frozen_balanceOf(address _account) internal view returns (uint) {
    }
}
contract TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public;
}
contract KickToken is AccountFrozenBalances {
    string public name;
    string public symbol;
    uint8 public decimals;
    bool public burnallow;
    bool public paused;
    address public owner;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor (string memory _name, string memory _symbol, uint8 _decimals) public {
    }
    mapping (address => bool) private _whitelisted;
    function addWhitelisted(address account) public onlyOwner {
    }
    function removeWhitelisted(address account) public onlyOwner {
    }
    function pauseTrigger() public onlyOwner {
    }
    modifier whenBurn() {
    }
    modifier canTransfer() {
    }
    mapping (address => bool) private _minters;
    function addToMinters(address account) public onlyOwner {
    }
    function removeFromMinters(address account) public onlyOwner {
    }
    modifier onlyMinter() {
    }
    mapping (address => bool) private _melters;
    function addToMelters(address account) public onlyOwner {
    }
    function removeFromMelters(address account) public onlyOwner {
    }
    modifier onlyMelter() {
    }
    modifier onlyOwner() {
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public pendingOwner;
    modifier onlyPendingOwner() {
    }
    function transferOwnership(address newOwner) public onlyOwner {
    }
    function claimOwnership() public onlyPendingOwner {
    }
    function burnTrigger() public onlyOwner {
    }
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
    }
    function balanceOf(address account) public view returns (uint256) {
    }
    function transfer(address recipient, uint256 amount) public canTransfer returns (bool) {
    }
    function allowance(address _owner, address spender) public view returns (uint256) {
    }
    function approve(address spender, uint256 value) public returns (bool) {
    }
    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool) {
    }
    function transferFrom(address sender, address recipient, uint256 amount) public canTransfer returns (bool) {
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(<FILL_ME>);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
    }
    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
    }
    function _burn(address account, uint256 value) internal {
    }
    function _approve(address _owner, address spender, uint256 value) internal {
    }
    function _burnFrom(address account, uint256 amount) internal {
    }
    function burn(uint256 amount) public whenBurn {
    }
    function burnFrom(address account, uint256 amount) public whenBurn {
    }
    function destroy(address account, uint256 amount) public onlyOwner {
    }
    function destroyFrozen(address account, uint256 amount) public onlyOwner {
    }
    function mintBatchToken(address[] memory accounts, uint256[] memory amounts) public onlyMinter returns (bool) {
    }
    event Freeze(address from, uint256 amount);
    event Melt(address from, uint256 amount);
    event MintFrozen(address to, uint256 amount);
    event FrozenTransfer(address indexed from, address indexed to, uint256 value);
    function _freeze(address account, uint256 amount) internal {
    }
    function _mintfrozen(address account, uint256 amount) internal {
    }
    function _melt(address account, uint256 amount) internal {
    }
    function _burnFrozen(address account, uint256 amount) internal {
    }
    function transferFrozenToken(address from, address to, uint256 amount) public onlyOwner returns (bool) {
    }
    function freezeTokens(address account, uint256 amount) public onlyOwner returns (bool) {
    }
    function meltTokens(address account, uint256 amount) public onlyMelter returns (bool) {
    }
    function mintFrozenTokens(address account, uint256 amount) public onlyOwner returns (bool) {
    }
    function mintBatchFrozenTokens(address[] memory accounts, uint256[] memory amounts) public onlyMinter returns (bool) {
    }
}