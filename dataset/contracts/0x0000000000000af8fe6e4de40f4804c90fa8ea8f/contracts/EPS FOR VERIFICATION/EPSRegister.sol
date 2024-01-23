// SPDX-License-Identifier: BUSL-1.1
// EPS Contracts v2.0.0

pragma solidity 0.8.17;
import "./IERC721DelegateRegister.sol";
import "./IERC1155DelegateRegister.sol";
import "./IERC20DelegateRegister.sol";
import "./ProxyRegister.sol";
import "./ENSReverseRegistrar.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 *
 * @dev The EPS Register contract, implementing the proxy and deligate registers
 *
 */
contract EPSRegister is ProxyRegister {
  using SafeERC20 for IERC20;

  struct MigratedRecord {
    address hot;
    address cold;
    address delivery;
  }

  // Record migration complete:
  bool public migrationComplete;

  ENSReverseRegistrar public ensReverseRegistrar;

  // EPS treasury address:
  address public treasury;

  // EPS ERC721 delegation register
  IERC721DelegateRegister public erc721DelegationRegister;
  bool public erc721DelegationRegisterAddressLocked;

  // EPS ERC1155 delegation register
  IERC1155DelegateRegister public erc1155DelegationRegister;
  bool public erc1155DelegationRegisterAddressLocked;

  // EPS ERC20 delegation register
  IERC20DelegateRegister public erc20DelegationRegister;
  bool public erc20DelegationRegisterAddressLocked;

  // Count of active ETH addresses for total supply
  uint256 public activeEthAddresses = 1;

  // 'Air drop' of EPSAPI to every address
  uint256 public epsAPIBalance = 10000 * (10**decimals());

  error ColdWalletCannotInteractUseHot();
  error EthWithdrawFailed();
  error UnknownAmount();
  error RegisterAddressLocked();
  error MigrationIsAllowedOnceOnly();

  event ERC20FeeUpdated(address erc20, uint256 erc20Fee_);
  event MigrationComplete();
  event Transfer(address indexed from, address indexed to, uint256 value);
  event ENSReverseRegistrarSet(address ensReverseRegistrarAddress);

  /**
   * @dev Constructor - change ownership
   */
  constructor() {
    _transferOwnership(0x9F0773aF2b1d3f7cC7030304548A823B4E6b13bB);
  }

  // ======================================================
  // VIEW METHODS
  // ======================================================

  /**
   * @dev beneficiaryOf: Returns the beneficiary of the `tokenId` token for an ERC721
   */
  function beneficiaryOf(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) external view returns (address beneficiary_) {
    // 1 Check for an active delegation. We need a concept of a 'senior right', which
    // we have elected to be airdrop rights, being the right of the holder to receive
    // free benefits associated with being a beneficiary. If we are looking for a beneficiary
    // rights index out of bounds default to an airdrop rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    beneficiary_ = erc721DelegationRegister.getBeneficiaryByRight(
      tokenContract_,
      tokenId_,
      rightsIndex_
    );

    if (beneficiary_ == address(0)) {
      // 2 No delegation. Get the owner:
      beneficiary_ = IERC721(tokenContract_).ownerOf(tokenId_);

      // 3 Check if this is a proxied benefit
      if (coldIsLive(beneficiary_)) {
        beneficiary_ = coldToHot[beneficiary_];
      }
    }
  }

  /**
   * @dev beneficiaryBalance: Returns the beneficiary balance of ETH.
   */
  function beneficiaryBalance(address queryAddress_)
    external
    view
    returns (uint256 balance_)
  {
    // Get any balances held at a nominated cold address
    if (hotIsLive(queryAddress_)) {
      // This is a hot address with a current record - include the balance
      // held natively by this address and the cold:
      balance_ += queryAddress_.balance;

      balance_ += hotToRecord[queryAddress_].cold.balance;
    } else {
      // Check if this is cold wallet on an active record. If so do not include balance as that is absorbed into the proxy
      if (!coldIsLive(queryAddress_)) {
        balance_ += queryAddress_.balance;
      }
    }
  }

  /**
   * @dev beneficiaryBalanceOf: Returns the beneficiary balance for an ERC721
   */
  function beneficiaryBalanceOf(
    address queryAddress_,
    address tokenContract_,
    uint256 rightsIndex_
  ) external view returns (uint256 balance_) {
    // 1a If this is a delegation container the balance is always 0, as the balance associated
    // will be for the benefit of either the original asset owner or the delegate, depending
    // on the delegation parameters:
    if (erc721DelegationRegister.containerToDelegationId(queryAddress_) != 0) {
      return (0);
    }

    // 1b We need a concept of a 'senior right', which we have elected to be airdrop rights,
    // being the right of the holder to receive free benefits associated with being a beneficiary.
    // If we are looking for a beneficiary rights index out of bounds default to an airdrop
    // rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    // 2 Get delegated balances:
    balance_ = erc721DelegationRegister.getBalanceByRight(
      tokenContract_,
      queryAddress_,
      rightsIndex_
    );

    // 3 Add any balances held at a nominated cold address
    if (hotIsLive(queryAddress_)) {
      // This is a hot address with a current record - add on the balances
      // held natively by this address and the cold:
      balance_ += (IERC721(tokenContract_).balanceOf(queryAddress_));

      address cold = hotToRecord[queryAddress_].cold;

      balance_ += IERC721(tokenContract_).balanceOf(cold);
    } else {
      // Check if this is cold wallet on an active record. If so do not include balance as that is absorbed into the proxy
      if (!coldIsLive(queryAddress_)) {
        balance_ += IERC721(tokenContract_).balanceOf(queryAddress_);
      }
    }
  }

  /**
   * @dev beneficiaryBalanceOf1155: Returns the beneficiary balance for an ERC1155.
   */
  function beneficiaryBalanceOf1155(
    address queryAddress_,
    address tokenContract_,
    uint256 id_,
    uint256 rightsIndex_
  ) external view returns (uint256 balance_) {
    // 1a If this is a delegation container the balance is always 0, as the balance associated
    // will be for the benefit of either the original asset owner or the delegate, depending
    // on the delegation parameters:
    if (erc1155DelegationRegister.containerToDelegationId(queryAddress_) != 0) {
      return (0);
    }

    // 1b We need a concept of a 'senior right', which we have elected to be airdrop rights,
    // being the right of the holder to receive free benefits associated with being a beneficiary.
    // If we are looking for a beneficiary rights index out of bounds default to an airdrop
    // rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    // 2 Get delegated balances:
    balance_ = erc1155DelegationRegister.getBalanceByRight(
      tokenContract_,
      id_,
      queryAddress_,
      rightsIndex_
    );

    // Add any balances held at a nominated cold address
    if (hotIsLive(queryAddress_)) {
      // This is a hot address with a current record - add on the balances
      // held natively by this address and the cold:
      balance_ += (IERC1155(tokenContract_).balanceOf(queryAddress_, id_));

      address cold = hotToRecord[queryAddress_].cold;

      balance_ += IERC1155(tokenContract_).balanceOf(cold, id_);
    } else {
      // Check if this is cold wallet on an active record. If so do not include balance as that is absorbed into the proxy
      if (!coldIsLive(queryAddress_)) {
        balance_ += IERC1155(tokenContract_).balanceOf(queryAddress_, id_);
      }
    }
  }

  /**
   * @dev beneficiaryBalanceOf20: Returns the beneficiary balance for an ERC20 or ERC777
   */
  function beneficiaryBalanceOf20(
    address queryAddress_,
    address tokenContract_,
    uint256 rightsIndex_
  ) external view returns (uint256 balance_) {
    // 1a If this is a delegation container the balance is always 0, as the balance associated
    // will be for the benefit of either the original asset owner or the delegate, depending
    // on the delegation parameters:
    if (erc20DelegationRegister.containerToDelegationId(queryAddress_) != 0) {
      return (0);
    }

    // 1b We need a concept of a 'senior right', which we have elected to be airdrop rights,
    // being the right of the holder to receive free benefits associated with being a beneficiary.
    // If we are looking for a beneficiary rights index out of bounds default to an airdrop
    // rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    // 2 Get delegated balances:
    balance_ = erc20DelegationRegister.getBalanceByRight(
      tokenContract_,
      queryAddress_,
      rightsIndex_
    );

    // 3 Add any balances held at a nominated cold address
    if (hotIsLive(queryAddress_)) {
      // This is a hot address with a current record - add on the balances
      // held natively by this address and the cold:
      balance_ += (IERC20(tokenContract_).balanceOf(queryAddress_));

      address cold = hotToRecord[queryAddress_].cold;

      balance_ += IERC20(tokenContract_).balanceOf(cold);
    } else {
      // Check if this is cold wallet on an active record. If so do not include balance as that is absorbed into the proxy
      if (!coldIsLive(queryAddress_)) {
        balance_ += IERC20(tokenContract_).balanceOf(queryAddress_);
      }
    }
  }

  /**
   * @dev getAddresses721: Returns the register addresses for the passed address and rights index for ERC721
   *
     Possible scenarios are:
   
      1) The receivedAddress_ is NOT on the proxy register and is NOT on the delegate register
         In this instance the return values will be:
          - proxyAddresses_: 
            - The recievedAddress_ at index 0
          - the receivedAddress_ as the delivery address
   
      2) The receivedAddress_ is a HOT address on the proxy register and is NOT on the delegate register
         In this instance the return values will be:
          - proxyAddresses_:
            - The receivedAddress_ at index 0
            - The COLD address at index 1
          - DELIVERY address as the delivery address

      3) The receivedAddress_ is a COLD address on the proxy register (whether it  has entries on the 
           delegate register or not)
          - proxyAddresses_:
            - NOTHING (i.e. empty array)
          - the receivedAddress_ as the delivery address 

      4) The receivedAddress_ is NOT on the proxy register BUT it DOES have entries on the delegate register
         In this instance the return values will be:
          - proxyAddresses_: 
            - The recievedAddress_ at index 0
            - The delegate register entries at index 1 to n
          - the receivedAddress_ as the delivery address

      5) The receivedAddress_ IS on the proxy register AND has entries on the delegate register
         In this instance the return values will be:
          - proxyAddresses_: 
            - The recievedAddress_ at index 0
            - The COLD address at index 1
            - The delegate register entries at index 2 to n
           - DELIVERY address as the delivery address

      Some points to note:
        * Index 0 in the returned address array will ALWAYS be the receivedAddress_ address UNLESS it's the address
          is a COLD wallet, in which case the array is empty. This enforces that a COLD wallet has no
          rights in its own right WITHOUT us needing to revert and have the caller handle the situation
        * Therefore if you wish to IGNORE the hot address, start any iteration over the returned list from index 1
          onwards. Index 1 (if it exists) will always either be the COLD address or the first entry from the delegate register.

   *
   */
  function getAddresses721(address receivedAddress_, uint256 rightsIndex_)
    public
    view
    returns (address[] memory proxyAddresses_, address delivery_)
  {
    // We need a concept of a 'senior right', which
    // we have elected to be airdrop rights, being the right of the holder to receive
    // free benefits associated with being a beneficiary. If we are looking for a beneficiary
    // rights index out of bounds default to an airdrop rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    address cold;
    delivery_ = receivedAddress_;

    if (coldIsLive(receivedAddress_)) {
      return (proxyAddresses_, receivedAddress_);
    }

    if (hotIsLive(receivedAddress_)) {
      cold = hotToRecord[receivedAddress_].cold;
      delivery_ = hotToRecord[receivedAddress_].delivery;
    }

    return (
      erc721DelegationRegister.getAllAddressesByRightsIndex(
        receivedAddress_,
        rightsIndex_,
        cold,
        true
      ),
      delivery_
    );
  }

  /**
   * @dev getAddresses1155: Returns the register addresses for the passed address and rights index for ERC1155
   *
   */
  function getAddresses1155(address receivedAddress_, uint256 rightsIndex_)
    public
    view
    returns (address[] memory proxyAddresses_, address delivery_)
  {
    // We need a concept of a 'senior right', which
    // we have elected to be airdrop rights, being the right of the holder to receive
    // free benefits associated with being a beneficiary. If we are looking for a beneficiary
    // rights index out of bounds default to an airdrop rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    address cold;
    delivery_ = receivedAddress_;

    if (coldIsLive(receivedAddress_)) {
      return (proxyAddresses_, receivedAddress_);
    }

    if (hotIsLive(receivedAddress_)) {
      cold = hotToRecord[receivedAddress_].cold;
      delivery_ = hotToRecord[receivedAddress_].delivery;
    }

    return (
      erc1155DelegationRegister.getAllAddressesByRightsIndex(
        receivedAddress_,
        rightsIndex_,
        cold,
        true
      ),
      delivery_
    );
  }

  /**
   * @dev getAddresses20: Returns the register addresses for the passed address and rights index for ERC20 and 777
   *
   */
  function getAddresses20(address receivedAddress_, uint256 rightsIndex_)
    public
    view
    returns (address[] memory proxyAddresses_, address delivery_)
  {
    // We need a concept of a 'senior right', which
    // we have elected to be airdrop rights, being the right of the holder to receive
    // free benefits associated with being a beneficiary. If we are looking for a beneficiary
    // rights index out of bounds default to an airdrop rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    address cold;
    delivery_ = receivedAddress_;

    if (coldIsLive(receivedAddress_)) {
      return (proxyAddresses_, receivedAddress_);
    }

    if (hotIsLive(receivedAddress_)) {
      cold = hotToRecord[receivedAddress_].cold;
      delivery_ = hotToRecord[receivedAddress_].delivery;
    }

    return (
      erc20DelegationRegister.getAllAddressesByRightsIndex(
        receivedAddress_,
        rightsIndex_,
        cold,
        true
      ),
      delivery_
    );
  }

  /**
   * @dev getAllAddresses: Returns ALL register addresses for the passed address and rights index
   *
   */
  function getAllAddresses(address receivedAddress_, uint256 rightsIndex_)
    public
    view
    returns (
      address[] memory erc721Addresses_,
      address[] memory erc1155Addresses_,
      address[] memory erc20Addresses_,
      address delivery_
    )
  {
    // We need a concept of a 'senior right', which
    // we have elected to be airdrop rights, being the right of the holder to receive
    // free benefits associated with being a beneficiary. If we are looking for a beneficiary
    // rights index out of bounds default to an airdrop rights query (rights index position 1)
    if (rightsIndex_ == 0 || rightsIndex_ > 15) {
      rightsIndex_ = 1;
    }

    address cold;
    delivery_ = receivedAddress_;

    if (coldIsLive(receivedAddress_)) {
      return (
        erc721Addresses_,
        erc1155Addresses_,
        erc20Addresses_,
        receivedAddress_
      );
    }

    if (hotIsLive(receivedAddress_)) {
      cold = hotToRecord[receivedAddress_].cold;
      delivery_ = hotToRecord[receivedAddress_].delivery;
    }

    if (
      address(erc721DelegationRegister) == address(0) &&
      address(erc1155DelegationRegister) == address(0) &&
      address(erc20DelegationRegister) == address(0)
    ) {
      // This is unexpected, but theoretically possible. In this case, return
      // the base addresses in the first return array:
      uint256 addIndexes;
      if (cold != address(0)) {
        addIndexes = 2;
      } else {
        addIndexes = 1;
      }

      address[] memory baseAddresses = new address[](addIndexes);

      baseAddresses[0] = receivedAddress_;
      if (cold != address(0)) {
        baseAddresses[1] = cold;
      }
      return (baseAddresses, erc1155Addresses_, erc20Addresses_, delivery_);
    } else {
      bool includeBaseAddresses = true;

      if (address(erc721DelegationRegister) != address(0)) {
        erc721Addresses_ = erc721DelegationRegister
          .getAllAddressesByRightsIndex(
            receivedAddress_,
            rightsIndex_,
            cold,
            includeBaseAddresses
          );
        includeBaseAddresses = false;
      }

      if (address(erc1155DelegationRegister) != address(0)) {
        erc1155Addresses_ = erc1155DelegationRegister
          .getAllAddressesByRightsIndex(
            receivedAddress_,
            rightsIndex_,
            cold,
            includeBaseAddresses
          );
        includeBaseAddresses = false;
      }

      if (address(erc20DelegationRegister) != address(0)) {
        erc20Addresses_ = erc20DelegationRegister.getAllAddressesByRightsIndex(
          receivedAddress_,
          rightsIndex_,
          cold,
          includeBaseAddresses
        );
        includeBaseAddresses = false;
      }
    }
    return (erc721Addresses_, erc1155Addresses_, erc20Addresses_, delivery_);
  }

  /**
   * @dev getColdAndDeliveryAddresses: Returns the register address details (cold and delivery address) for a passed hot address
   */
  function getColdAndDeliveryAddresses(address _receivedAddress)
    public
    view
    returns (
      address cold,
      address delivery,
      bool isProxied
    )
  {
    if (coldIsLive(_receivedAddress)) revert ColdWalletCannotInteractUseHot();

    if (hotIsLive(_receivedAddress)) {
      return (
        hotToRecord[_receivedAddress].cold,
        hotToRecord[_receivedAddress].delivery,
        true
      );
    } else {
      return (_receivedAddress, _receivedAddress, false);
    }
  }

  // ======================================================
  // ADMIN FUNCTIONS
  // ======================================================

  /**
   * @dev setRegisterFee: set the fee for accepting a registration:
   */
  function setRegisterFee(uint256 registerFee_) external onlyOwner {
    proxyRegisterFee = registerFee_;
  }

  /**
   * @dev setDeletionNominalEth: set the nominal ETH transfer that represents an address ending a proxy
   */
  function setDeletionNominalEth(uint256 deleteNominalEth_) external onlyOwner {
    deletionNominalEth = deleteNominalEth_;
  }

  /**
   *
   * @dev setRewardToken
   *
   */
  function setRewardToken(address rewardToken_) external onlyOwner {
    rewardToken = IOAT(rewardToken_);
    emit RewardTokenUpdated(rewardToken_);
  }

  /**
   *
   * @dev setRewardRate
   *
   */
  function setRewardRate(uint88 rewardRate_) external onlyOwner {
    if (rewardRateLocked) {
      revert RewardRateIsLocked();
    }
    rewardRate = rewardRate_;
    emit RewardRateUpdated(rewardRate_);
  }

  /**
   *
   * @dev lockRewardRate
   *
   */
  function lockRewardRate() external onlyOwner {
    rewardRateLocked = true;
    emit RewardRateLocked();
  }

  /**
   *
   * @dev setENSName (used to set reverse record so interactions with this contract are easy to
   * identify)
   *
   */
  function setENSName(string memory ensName_) external onlyOwner {
    ensReverseRegistrar.setName(ensName_);
  }

  /**
   * @dev setTreasuryAddress: set the treasury address:
   */
  function setTreasuryAddress(address treasuryAddress_) public onlyOwner {
    treasury = treasuryAddress_;
  }

  /**
   * @dev setERC721DelegationRegister: set the delegation register address:
   */
  function setERC721DelegationRegister(address erc721DelegationRegister_)
    public
    onlyOwner
  {
    if (erc721DelegationRegisterAddressLocked) {
      revert RegisterAddressLocked();
    }
    erc721DelegationRegister = IERC721DelegateRegister(
      erc721DelegationRegister_
    );
  }

  /**
   * @dev lockERC721DelegationRegisterAddress
   */
  function lockERC721DelegationRegisterAddress() public onlyOwner {
    erc721DelegationRegisterAddressLocked = true;
  }

  /**
   * @dev setERC1155DelegationRegister: set the delegation register address:
   */
  function setERC1155DelegationRegister(address erc1155DelegationRegister_)
    public
    onlyOwner
  {
    if (erc1155DelegationRegisterAddressLocked) {
      revert RegisterAddressLocked();
    }
    erc1155DelegationRegister = IERC1155DelegateRegister(
      erc1155DelegationRegister_
    );
  }

  /**
   * @dev lockERC1155DelegationRegisterAddress
   */
  function lockERC1155DelegationRegisterAddress() public onlyOwner {
    erc1155DelegationRegisterAddressLocked = true;
  }

  /**
   * @dev setERC20DelegationRegister: set the delegation register address:
   */
  function setERC20DelegationRegister(address erc20DelegationRegister_)
    public
    onlyOwner
  {
    if (erc20DelegationRegisterAddressLocked) {
      revert RegisterAddressLocked();
    }
    erc20DelegationRegister = IERC20DelegateRegister(erc20DelegationRegister_);
  }

  /**
   * @dev lockERC20DelegationRegisterAddress
   */
  function lockERC20DelegationRegisterAddress() public onlyOwner {
    erc20DelegationRegisterAddressLocked = true;
  }

  /**
   * @dev setActiveEthAddresses: used in the psuedo total supply calc:
   */
  function setNNumberOfEthAddressesAndAirdropAmount(
    uint256 count_,
    uint256 air_
  ) public onlyOwner {
    activeEthAddresses = count_;
    epsAPIBalance = air_;
  }

  /**
   * @dev withdrawETH: withdraw eth to the treasury:
   */
  function withdrawETH(uint256 amount_) external onlyOwner {
    (bool success, ) = treasury.call{value: amount_}("");

    if (!success) revert EthWithdrawFailed();
  }

  /**
   * @dev withdrawERC20: Allow any ERC20s to be withdrawn Note, this is provided to enable the
   * withdrawal of payments using valid ERC20s. Assets sent here in error are retrieved with
   * rescueERC20
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external onlyOwner {
    token_.safeTransfer(treasury, amount_);
  }

  /**
   * @dev rescueERC20: Allow any ERC20s to be rescued. Note, this is provided to enable the
   * withdrawal assets sent here in error. ERC20 fee payments are withdrawn to the treasury.
   * in withDrawERC1155
   */
  function rescueERC20(IERC20 token_, uint256 amount_) external onlyOwner {
    token_.safeTransfer(owner(), amount_);
  }

  /**
   * @dev rescueERC721: Allow any ERC721s to be rescued. Note, all delegated ERC721s are in their
   * own contract, NOT on this contract. This is provided to enable the withdrawal of
   * any assets sent here in error using transferFrom not safeTransferFrom.
   */

  function rescueERC721(IERC721 token_, uint256 tokenId_) external onlyOwner {
    token_.transferFrom(address(this), owner(), tokenId_);
  }

  /**
   * @dev rescueERC1155: Allow any ERC1155s to be rescued. Note, all delegated ERC1155s are in their
   * own contract, NOT on this contract. This is provided to enable the withdrawal of
   * any assets sent here in error using transferFrom not safeTransferFrom.
   */

  function rescueERC1155(IERC1155 token_, uint256 tokenId_) external onlyOwner {
    token_.safeTransferFrom(
      address(this),
      owner(),
      tokenId_,
      token_.balanceOf(address(this), tokenId_),
      ""
    );
  }

  /**
   *
   * @dev setERC20Fee
   *
   */
  function setERC20Fee(address erc20_, uint256 erc20Fee_) external onlyOwner {
    erc20PerTransactionFee[erc20_] = erc20Fee_;
    emit ERC20FeeUpdated(erc20_, erc20Fee_);
  }

  /**
   *
   * @dev setENSReverseRegistrar
   *
   */
  function setENSReverseRegistrar(address ensReverseRegistrar_)
    external
    onlyOwner
  {
    ensReverseRegistrar = ENSReverseRegistrar(ensReverseRegistrar_);
    emit ENSReverseRegistrarSet(ensReverseRegistrar_);
  }

  /**
   * @dev One-off migration routine to bring in register details from a previous version
   */
  function migration(MigratedRecord[] memory migratedRecords_)
    external
    onlyOwner
  {
    if (migrationComplete) {
      revert MigrationIsAllowedOnceOnly();
    }

    for (uint256 i = 0; i < migratedRecords_.length; ) {
      MigratedRecord memory currentRecord = migratedRecords_[i];

      _processNomination(
        currentRecord.hot,
        currentRecord.cold,
        currentRecord.delivery,
        true,
        0
      );

      _acceptNomination(currentRecord.hot, currentRecord.cold, 0, 0);

      unchecked {
        i++;
      }
    }

    migrationComplete = true;

    emit MigrationComplete();
  }

  // ======================================================
  // ETH CALL ENTRY POINT
  // ======================================================

  /**
   *
   * @dev receive: Wallets need never connect directly to add to EPS register, rather they can
   * interact through ETH or ERC20 transfers. This 'air gaps' your wallet(s) from
   * EPS. ETH transfers can be used to pay the fee or delete a record (sent from either
   * the hot or the cold wallet).
   *
   */
  receive() external payable {
    if (
      msg.value != proxyRegisterFee &&
      msg.value != deletionNominalEth &&
      erc721DelegationRegister.containerToDelegationId(msg.sender) == 0 &&
      erc1155DelegationRegister.containerToDelegationId(msg.sender) == 0 &&
      erc20DelegationRegister.containerToDelegationId(msg.sender) == 0 &&
      msg.sender != owner()
    ) revert UnknownAmount();

    if (msg.value == proxyRegisterFee) {
      _payFee(msg.sender);
    } else if (msg.value == deletionNominalEth) {
      // Either hot or cold requesting a deletion:
      _deleteRecord(msg.sender, 0);
    }
  }

  /**
   * @dev _payFee: process receipt of payment
   */
  function _payFee(address from_) internal {
    // 1) If our from address is a hot address and the proxy is pending payment we
    // can record this as paid and put the record live:
    if (hotToRecord[from_].status == ProxyStatus.PendingPayment) {
      _recordLive(
        from_,
        hotToRecord[from_].cold,
        hotToRecord[from_].delivery,
        hotToRecord[from_].provider
      );
    } else if (
      // 2) If our from address is a cold address and the proxy is pending payment we
      // can record this as paid and put the record live:
      hotToRecord[coldToHot[from_]].status == ProxyStatus.PendingPayment
    ) {
      _recordLive(
        coldToHot[from_],
        from_,
        hotToRecord[coldToHot[from_]].delivery,
        hotToRecord[coldToHot[from_]].provider
      );
    } else revert NoPaymentPendingForAddress();
  }

  // ======================================================
  // ERC20 METHODS (to expose API)
  // ======================================================

  /**
   * @dev Returns the name of the token.
   */
  function name() public pure returns (string memory) {
    return "EPS API";
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public pure returns (string memory) {
    return "EPSAPI";
  }

  function balanceOf(address) public view returns (uint256) {
    return epsAPIBalance;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view returns (uint256) {
    return activeEthAddresses * epsAPIBalance;
  }

  /**
   * @dev Doesn't move tokens at all. There was no spoon and there are no tokens.
   * Rather the quantity being 'sent' denotes the action the user is taking
   * on the EPS register, and the address they are 'sent' to is the address that is
   * being referenced by this request.
   */
  function transfer(address to, uint256 amount) public returns (bool) {
    _tokenAPICall(msg.sender, to, amount);

    emit Transfer(msg.sender, to, 0);

    return (true);
  }
}
