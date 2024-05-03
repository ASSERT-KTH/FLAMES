// SWC-Code With No Effects: L1 - L792
/**
 *  The Consumer Contract Wallet
 *  Copyright (C) 2019 The Contract Wallet Company Limited
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
pragma solidity ^0.4.25;
import "./licence.sol";
import "./internals/ownable.sol";
import "./internals/controllable.sol";
import "./internals/ensResolvable.sol";
import "./internals/tokenWhitelistable.sol";
import "./externals/SafeMath.sol";
import "./externals/ERC20.sol";
import "./externals/ERC165.sol";
/// @title ControllableOwnable combines Controllable and Ownable
/// @dev providing an additional modifier to check if Owner or Controller
contract ControllableOwnable is Controllable, Ownable {
    /// @dev Check if the sender is the Owner or one of the Controllers
    modifier onlyOwnerOrController() {
    }
}
/// @title AddressWhitelist provides payee-whitelist functionality.
/// @dev This contract will allow the user to maintain a whitelist of addresses
/// @dev These addresses will live outside of the various spend limits
contract AddressWhitelist is ControllableOwnable {
    using SafeMath for uint256;
    event AddedToWhitelist(address _sender, address[] _addresses);
    event SubmittedWhitelistAddition(address[] _addresses, bytes32 _hash);
    event CancelledWhitelistAddition(address _sender, bytes32 _hash);
    event RemovedFromWhitelist(address _sender, address[] _addresses);
    event SubmittedWhitelistRemoval(address[] _addresses, bytes32 _hash);
    event CancelledWhitelistRemoval(address _sender, bytes32 _hash);
    mapping(address => bool) public whitelistMap;
    address[] public whitelistArray;
    address[] private _pendingWhitelistAddition;
    address[] private _pendingWhitelistRemoval;
    bool public submittedWhitelistAddition;
    bool public submittedWhitelistRemoval;
    bool public isSetWhitelist;
    /// @dev Check if the provided addresses contain the owner or the zero-address address.
    modifier hasNoOwnerOrZeroAddress(address[] _addresses) {
    }
    /// @dev Check that neither addition nor removal operations have already been submitted.
    modifier noActiveSubmission() {
    }
    /// @dev Getter for pending addition array.
    function pendingWhitelistAddition() external view returns (address[]) {
    }
    /// @dev Getter for pending removal array.
    function pendingWhitelistRemoval() external view returns (address[]) {
    }
    /// @dev Add initial addresses to the whitelist.
    /// @param _addresses are the Ethereum addresses to be whitelisted.
    function setWhitelist(address[] _addresses) external onlyOwner hasNoOwnerOrZeroAddress(_addresses) {
    }
    /// @dev Add addresses to the whitelist.
    /// @param _addresses are the Ethereum addresses to be whitelisted.
    function submitWhitelistAddition(address[] _addresses) external onlyOwner noActiveSubmission hasNoOwnerOrZeroAddress(_addresses) {
    }
    /// @dev Confirm pending whitelist addition.
    /// @dev This will only ever be applied post 2FA, by one of the Controllers
    /// @param _hash is the hash of the pending whitelist array, a form of lamport lock
    function confirmWhitelistAddition(bytes32 _hash) external onlyController {
    }
    /// @dev Cancel pending whitelist addition.
    function cancelWhitelistAddition(bytes32 _hash) external onlyOwnerOrController {
    }
    /// @dev Remove addresses from the whitelist.
    /// @param _addresses are the Ethereum addresses to be removed.
    function submitWhitelistRemoval(address[] _addresses) external onlyOwner noActiveSubmission {
    }
    /// @dev Confirm pending removal of whitelisted addresses.
    function confirmWhitelistRemoval(bytes32 _hash) external onlyController {
    }
    /// @dev Cancel pending removal of whitelisted addresses.
    function cancelWhitelistRemoval(bytes32 _hash) external onlyOwnerOrController {
    }
    /// @dev Method used to hash our whitelist address arrays.
    function calculateHash(address[] _addresses) public pure returns (bytes32) {
    }
}
/// @title DailyLimitTrait This trait allows for daily limits to be included in other contracts.
/// This contract will allow for a DailyLimit object to be instantiated and used.
contract DailyLimitTrait {
    using SafeMath for uint256;
    struct DailyLimit {
        uint value;
        uint available;
        uint limitDay;
        uint pending;
        bool set;
    }
    /// @dev Returns the available daily balance - accounts for daily limit reset.
    /// @return amount of available to spend within the current day in base units.
    function _getAvailableLimit(DailyLimit storage dl) internal view returns (uint) {
    }
    /// @dev Use up amount within the daily limit. Will fail if amount is larger than daily limit.
    function _enforceLimit(DailyLimit storage dl, uint _amount) internal {
    }
    /// @dev Set the daily limit.
    /// @param _amount is the daily limit amount in base units.
    function _setLimit(DailyLimit storage dl, uint _amount) internal {
    }
    /// @dev Submit a daily limit update, needs to be confirmed.
    /// @param _amount is the daily limit amount in base units.
    function _submitLimitUpdate(DailyLimit storage dl, uint _amount) internal {
    }
    /// @dev Confirm pending set daily limit operation.
    function _confirmLimitUpdate(DailyLimit storage dl, uint _amount) internal {
    }
    /// @dev Update available spend limit based on the daily reset.
    function _updateAvailableLimit(DailyLimit storage dl) private {
    }
    /// @dev Modify the spend limit and spend available based on the provided value.
    /// @dev _amount is the daily limit amount in wei.
    function _modifyLimit(DailyLimit storage dl, uint _amount) private {
    }
}
/// @title  it provides daily spend limit functionality.
contract SpendLimit is ControllableOwnable, DailyLimitTrait {
    event SetSpendLimit(address _sender, uint _amount);
    event SubmittedSpendLimitUpdate(uint _amount);
    DailyLimit internal _spendLimit;
    /// @dev Constructor initializes the daily spend limit in wei.
    constructor(uint _limit_) internal {
    }
    /// @dev Sets the initial daily spend (aka transfer) limit for non-whitelisted addresses.
    /// @param _amount is the daily limit amount in wei.
    function setSpendLimit(uint _amount) external onlyOwner {
    }
    /// @dev Submit a daily transfer limit update for non-whitelisted addresses.
    /// @param _amount is the daily limit amount in wei.
    function submitSpendLimitUpdate(uint _amount) external onlyOwner {
    }
    /// @dev Confirm pending set daily limit operation.
    function confirmSpendLimitUpdate(uint _amount) external onlyController {
    }
    function spendLimitAvailable() external view returns (uint) {
    }
    function spendLimitValue() external view returns (uint) {
    }
    function spendLimitSet() external view returns (bool) {
    }
    function spendLimitPending() external view returns (uint) {
    }
}
//// @title GasTopUpLimit provides daily limit functionality.
contract GasTopUpLimit is ControllableOwnable, DailyLimitTrait {
    event SetGasTopUpLimit(address _sender, uint _amount);
    event SubmittedGasTopUpLimitUpdate(uint _amount);
    uint constant private _MINIMUM_GAS_TOPUP_LIMIT = 1 finney;
    uint constant private _MAXIMUM_GAS_TOPUP_LIMIT = 500 finney;
    DailyLimit internal _gasTopUpLimit;
    /// @dev Constructor initializes the daily gas topup limit in wei.
    constructor() internal {
    }
    /// @dev Sets the daily gas top up limit.
    /// @param _amount is the gas top up amount in wei.
    function setGasTopUpLimit(uint _amount) external onlyOwner {
    }
    /// @dev Submit a daily gas top up limit update.
    /// @param _amount is the daily top up gas limit amount in wei.
    function submitGasTopUpLimitUpdate(uint _amount) external onlyOwner {
    }
    /// @dev Confirm pending set top up gas limit operation.
    function confirmGasTopUpLimitUpdate(uint _amount) external onlyController {
    }
    function gasTopUpLimitAvailable() external view returns (uint) {
    }
    function gasTopUpLimitValue() external view returns (uint) {
    }
    function gasTopUpLimitSet() external view returns (bool) {
    }
    function gasTopUpLimitPending() external view returns (uint) {
    }
}
/// @title LoadLimit provides daily load limit functionality.
contract LoadLimit is ControllableOwnable, DailyLimitTrait {
    event SetLoadLimit(address _sender, uint _amount);
    event SubmittedLoadLimitUpdate(uint _amount);
    uint constant private _MINIMUM_LOAD_LIMIT = 1 finney;
    uint private _maximumLoadLimit;
    DailyLimit internal _loadLimit;
    /// @dev Sets a daily card load limit.
    /// @param _amount is the card load amount in current stablecoin base units.
    function setLoadLimit(uint _amount) external onlyOwner {
        require(<FILL_ME>);
        _setLimit(_loadLimit, _amount);
        emit SetLoadLimit(msg.sender, _amount);
    }
    /// @dev Submit a daily load limit update.
    /// @param _amount is the daily load limit amount in wei.
    function submitLoadLimitUpdate(uint _amount) external onlyOwner {
    }
    /// @dev Confirm pending set load limit operation.
    function confirmLoadLimitUpdate(uint _amount) external onlyController {
    }
    function loadLimitAvailable() external view returns (uint) {
    }
    function loadLimitValue() external view returns (uint) {
    }
    function loadLimitSet() external view returns (bool) {
    }
    function loadLimitPending() external view returns (uint) {
    }
    /// @dev initializes the daily load limit.
    /// @param _maxLimit is the maximum load limit amount in stablecoin base units.
    function _initializeLoadLimit(uint _maxLimit) internal {
    }
}
//// @title Asset store with extra security features.
contract Vault is AddressWhitelist, SpendLimit, ERC165, TokenWhitelistable {
    using SafeMath for uint256;
    event Received(address _from, uint _amount);
    event Transferred(address _to, address _asset, uint _amount);
    /// @dev Supported ERC165 interface ID.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7; // solium-disable-line uppercase
    /// @dev Constructor initializes the vault with an owner address and spend limit. It also sets up the controllable and tokenWhitelist contracts with the right name registered in ENS.
    /// @param _owner_ is the owner account of the wallet contract.
    /// @param _transferable_ indicates whether the contract ownership can be transferred.
    /// @param _tokenWhitelistNameHash_ is the ENS name hash of the Token whitelist.
    /// @param _controllerNameHash_ is the ENS name hash of the controller.
    /// @param _spendLimit_ is the initial spend limit.
    constructor(address _owner_, bool _transferable_, bytes32 _tokenWhitelistNameHash_, bytes32 _controllerNameHash_, uint _spendLimit_) SpendLimit(_spendLimit_) Ownable(_owner_, _transferable_) Controllable(_controllerNameHash_) TokenWhitelistable(_tokenWhitelistNameHash_) public {}
    /// @dev Checks if the value is not zero.
    modifier isNotZero(uint _value) {
    }
    /// @dev Ether can be deposited from any source, so this contract must be payable by anyone.
    function() external payable {
    }
    /// @dev Returns the amount of an asset owned by the contract.
    /// @param _asset address of an ERC20 token or 0x0 for ether.
    /// @return balance associated with the wallet address in wei.
    function balance(address _asset) external view returns (uint) {
    }
    /// @dev Transfers the specified asset to the recipient's address.
    /// @param _to is the recipient's address.
    /// @param _asset is the address of an ERC20 token or 0x0 for ether.
    /// @param _amount is the amount of assets to be transferred in base units.
    function transfer(address _to, address _asset, uint _amount) external onlyOwner isNotZero(_amount) {
    }
    /// @dev Checks for interface support based on ERC165.
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
    }
    /// @dev Convert ERC20 token amount to the corresponding ether amount.
    /// @param _token ERC20 token contract address.
    /// @param _amount amount of token in base units.
    function convertToEther(address _token, uint _amount) public view returns (uint) {
    }
}
//// @title Asset wallet with extra security features, gas top up management and card integration.
contract Wallet is ENSResolvable, Vault, GasTopUpLimit, LoadLimit {
    event ToppedUpGas(address _sender, address _owner, uint _amount);
    event LoadedTokenCard(address _asset, uint _amount);
    event ExecutedTransaction(address _destination, uint _value, bytes _data);
    uint constant private _DEFAULT_MAX_STABLECOIN_LOAD_LIMIT = 10000; //10,000 USD
    /// @dev Is the registered ENS node identifying the licence contract.
    bytes32 private _licenceNode;
    /// @dev these are needed to allow for the executeTransaction method
    uint32 private constant _TRANSFER= 0xa9059cbb;
    uint32 private constant _APPROVE = 0x095ea7b3;
    /// @dev Constructor initializes the wallet top up limit and the vault contract.
    /// @param _owner_ is the owner account of the wallet contract.
    /// @param _transferable_ indicates whether the contract ownership can be transferred.
    /// @param _ens_ is the address of the ENS registry.
    /// @param _tokenWhitelistNameHash_ is the ENS name hash of the Token whitelist.
    /// @param _controllerNameHash_ is the ENS name hash of the Controller contract.
    /// @param _licenceNameHash_ is the ENS name hash of the Licence contract.
    /// @param _spendLimit_ is the initial spend limit.
    constructor(address _owner_, bool _transferable_, address _ens_, bytes32 _tokenWhitelistNameHash_, bytes32 _controllerNameHash_, bytes32 _licenceNameHash_, uint _spendLimit_) ENSResolvable(_ens_) Vault(_owner_, _transferable_, _tokenWhitelistNameHash_, _controllerNameHash_, _spendLimit_) public {
    }
    /// @dev Refill owner's gas balance, revert if the transaction amount is too large
    /// @param _amount is the amount of ether to transfer to the owner account in wei.
    function topUpGas(uint _amount) external isNotZero(_amount) onlyOwnerOrController {
    }
    /// @dev Load a token card with the specified asset amount.
    /// @dev the amount send should be inclusive of the percent licence.
    /// @param _asset is the address of an ERC20 token or 0x0 for ether.
    /// @param _amount is the amount of assets to be transferred in base units.
    function loadTokenCard(address _asset, uint _amount) external payable onlyOwner {
    }
    /// @dev This function allows for the owner to send transaction from the Wallet to arbitrary addresses
    /// @param _destination address of the transaction
    /// @param _value ETH amount in wei
    /// @param _data transaction payload binary
    function executeTransaction(address _destination, uint _value, bytes _data) external onlyOwner {
    }
    /// @return licence contract node registered in ENS.
    function licenceNode() external view returns (bytes32) {
    }
    /// @dev Convert ether or ERC20 token amount to the corresponding stablecoin amount.
    /// @param _token ERC20 token contract address.
    /// @param _amount amount of token in base units.
    function convertToStablecoin(address _token, uint _amount) public view returns (uint) {
    }
    /// @dev This function is taken from the Gnosis MultisigWallet: https://github.com/gnosis/MultiSigWallet/
    /// @dev License: https://github.com/gnosis/MultiSigWallet/blob/master/LICENSE
    /// @dev thanks :)
    /// @dev This calls proxies arbitrary transactions to addresses
    /// @param _destination address of the transaction
    /// @param _value ETH amount in wei
    /// @param _dataLength length of the transaction data
    /// @param _data transaction payload binary
    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function _externalCall(address _destination, uint _value, uint _dataLength, bytes _data) private returns (bool) {
    }
    /// @dev This function converts to an address
    /// @param _bts bytes
    /// @param _from start position
    function _bytesToAddress(bytes _bts, uint _from) private pure returns (address) {
    }
    /// @dev This function slicing bytes into uint32
    /// @param _bts some bytes
    /// @param _from  a start position
    function _bytesToUint32(bytes _bts, uint _from) private pure returns (uint32) {
    }
    /// @dev This function slices a uint
    /// @param _bts some bytes
    /// @param _from  a start position
    // credit to https://ethereum.stackexchange.com/questions/51229/how-to-convert-bytes-to-uint-in-solidity
    // and Nick Johnson https://ethereum.stackexchange.com/questions/4170/how-to-convert-a-uint-to-bytes-in-solidity/4177#4177
    function _sliceUint(bytes _bts, uint _from) private pure returns (uint) {
    }
}