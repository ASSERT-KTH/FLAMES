// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./interfaces/IKaijuMartExtended.sol";
import "./interfaces/IKaijuMartRedeemable.sol";

error KaijuMartEtherPaymentProcessor_InsufficientPermissions();
error KaijuMartEtherPaymentProcessor_InvalidLotState();
error KaijuMartEtherPaymentProcessor_InvalidValue();
error KaijuMartEtherPaymentProcessor_MustBeAKing();
error KaijuMartEtherPaymentProcessor_WithdrawFailed();

/**
                        .             :++-
                       *##-          +####*          -##+
                       *####-      :%######%.      -%###*
                       *######:   =##########=   .######*
                       *#######*-#############*-*#######*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       *################################*
                       :*******************************+.

                .:.
               *###%*=:
              .##########+-.
              +###############=:
              %##################%+
             =######################
             -######################++++++++++++++++++=-:
              =###########################################*:
               =#############################################.
  +####%#*+=-:. -#############################################:
  %############################################################=
  %##############################################################
  %##############################################################%=----::.
  %#######################################################################%:
  %##########################################+:    :+%#######################:
  *########################################*          *#######################
   -%######################################            %######################
     -%###################################%            #######################
       =###################################-          :#######################
     ....+##################################*.      .+########################
  +###########################################%*++*%##########################
  %#########################################################################*.
  %#######################################################################+
  ########################################################################-
  *#######################################################################-
  .######################################################################%.
     :+#################################################################-
         :=#####################################################:.....
             :--:.:##############################################+
   ::             +###############################################%-
  ####%+-.        %##################################################.
  %#######%*-.   :###################################################%
  %###########%*=*####################################################=
  %####################################################################
  %####################################################################+
  %#####################################################################.
  %#####################################################################%
  %######################################################################-
  .+*********************************************************************.
 * @title KaijuMartEtherPurchaseProcessor
 * @notice Create ether payment processors for KMart lots
 * @author Augminted Labs, LLC
 */
contract KaijuMartEtherPurchaseProcessor {
    IKaijuMartExtended public immutable KMART;

    event Purchase(
        uint256 indexed id,
        address indexed account,
        uint64 amount
    );

    struct Processor {
        uint104 price;
        bool enabled;
        bool isRedeemable;
        bool requiresKing;
        bool requiresSignature;
    }

    IDoorbusterManager public doorbusterManager;
    mapping(uint256 => Processor) public lotProcessors;

    constructor(IKaijuMartExtended kmart) {
        KMART = kmart;
        doorbusterManager = KMART.managerContracts().doorbuster;
    }

    /**
     * @notice Requires sender to have a KMart admin role
     */
    modifier onlyKMartAdmin() {
        if (!KMART.hasRole(bytes32(0), msg.sender))
            revert KaijuMartEtherPaymentProcessor_InsufficientPermissions();
        _;
    }

    /**
     * @notice Refresh the state of the KMart doorbuster manager contract
     */
    function refreshDoorbusterManager() public payable onlyKMartAdmin {
        doorbusterManager = KMART.managerContracts().doorbuster;
    }

    /**
     * @notice Set a lot payment processor
     * @param _lotId Lot to set a payment processor for
     * @param _processor Payment processor for a specified lot
     */
    function setLotProcessor(
        uint256 _lotId,
        Processor calldata _processor
    )
        public
        payable
        onlyKMartAdmin
    {
        IKaijuMartExtended.Lot memory lot = KMART.lots(_lotId);

        if (uint8(lot.lotType) == 0) revert KaijuMartEtherPaymentProcessor_InvalidLotState();

        lotProcessors[_lotId] = _processor;
        lotProcessors[_lotId].isRedeemable = address(lot.redeemer) != address(0);
    }

    /**
     * @notice Purchase from a KMart doorbuster lot with ETH
     * @param _lotId Lot to purchase from
     * @param _amount Quantity to purchase
     */
    function purchase(uint256 _lotId, uint32 _amount) public payable {
        Processor memory processor = lotProcessors[_lotId];

        if (!processor.enabled || processor.requiresSignature) revert KaijuMartEtherPaymentProcessor_InvalidLotState();
        if (msg.value != processor.price * _amount) revert KaijuMartEtherPaymentProcessor_InvalidValue();
        if (processor.requiresKing && !KMART.isKing(msg.sender)) revert KaijuMartEtherPaymentProcessor_MustBeAKing();

        doorbusterManager.purchase(_lotId, _amount);

        if (processor.isRedeemable)
            KMART.lots(_lotId).redeemer.kmartRedeem(_lotId, _amount, msg.sender);

        emit Purchase(_lotId, msg.sender, _amount);
    }

    /**
     * @notice Purchase from a KMart doorbuster lot with ETH
     * @param _lotId Lot to purchase from
     * @param _amount Quantity to purchase
     * @param _nonce Single use number encoded into signature
     * @param _signature Signature created by the doorbuster contract's `signer` account
     */
    function purchase(
        uint256 _lotId,
        uint32 _amount,
        uint256 _nonce,
        bytes calldata _signature
    )
        public
        payable
    {
        Processor memory processor = lotProcessors[_lotId];

        if (!processor.enabled || !processor.requiresSignature) revert KaijuMartEtherPaymentProcessor_InvalidLotState();
        if (msg.value != processor.price * _amount) revert KaijuMartEtherPaymentProcessor_InvalidValue();
        if (processor.requiresKing && !KMART.isKing(msg.sender)) revert KaijuMartEtherPaymentProcessor_MustBeAKing();

        doorbusterManager.purchase(_lotId, _amount, _nonce, _signature);

        if (processor.isRedeemable)
            KMART.lots(_lotId).redeemer.kmartRedeem(_lotId, _amount, msg.sender);

        emit Purchase(_lotId, msg.sender, _amount);
    }

    /**
     * @notice Send all ETH in the contract to a specified receiver
     * @param _receiver Address to receive all the ETH in the contract
     */
    function withdraw(address _receiver) public payable onlyKMartAdmin {
        (bool success, ) = _receiver.call{ value: address(this).balance }("");
        if (!success) revert KaijuMartEtherPaymentProcessor_WithdrawFailed();
    }
}