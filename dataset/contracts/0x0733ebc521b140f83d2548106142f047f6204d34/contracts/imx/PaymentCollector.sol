// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PaymentCollector is Ownable {
    using SafeERC20 for IERC20;

    mapping(uint => bool) public transactionProcessed;

    address public signer;

    event Deposit(uint indexed offchainId, address sender, address token, uint amount);

    constructor(address _signer) {
        require(_signer != address(0), "Non zero address!");
        signer = _signer;
    }

    function deposit(
        uint offchainId,
        uint amount,
        address token, 
        uint timestamp,
        bytes memory signature
    ) external payable {
        require(
          validateSignature(offchainId, amount, token, timestamp, signature), 
          "Invalid signature."
        );
        require(!transactionProcessed[offchainId], "Transaction already processed.");
        require(timestamp > block.timestamp, "Signature expired.");

        transactionProcessed[offchainId] = true;

        if (token == address(0)) {
            require(msg.value >= amount, "Insufficient amount.");
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        emit Deposit(offchainId, msg.sender, token, amount);
    }

    function withdraw(address token) external onlyOwner {
      if (token == address(0)) {
            (bool success, ) = owner().call{value: address(this).balance}("");
            require(success, "receiver rejected transfer");
        } else {
            IERC20(token).safeTransfer(owner(), IERC20(token).balanceOf(address(this)));
        }
    }

    /**
    * @dev Validates signature for sending.
    * @param offchainId offchainId.
    * @param amount Amount to be sent.
    * @param token Token to be sent.
    * @param timestamp timestamp of expiration.
    * @param signature Signature of above data.
    */
    function validateSignature(
        uint offchainId,
        uint amount,
        address token,
        uint timestamp,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(
                msg.sender,
                offchainId,
                amount,
                token,
                timestamp,
                address(this)
            )
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        address receivedAddress = ECDSA.recover(message, signature);
        return receivedAddress == signer;
    }

    /**
     * @dev Sets signer.
     * @param _signer Address we are setting.
     */
    function setSigner(address _signer)
        external
        onlyOwner
    {
        require(_signer != address(0), "Non zero address!");
        signer = _signer;
    }
}
