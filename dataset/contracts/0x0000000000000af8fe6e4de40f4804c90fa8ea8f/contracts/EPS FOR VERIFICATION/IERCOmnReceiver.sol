// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERCOmnReceiver {
  function onTokenTransfer(
    address sender,
    uint256 value,
    bytes memory data
  ) external payable;
}
