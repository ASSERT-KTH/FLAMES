// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./IKaijuMart.sol";

interface IKaijuMartExtended is IKaijuMart, IAccessControl {
    function managerContracts() external view returns (ManagerContracts memory);
    function lots(uint256 lotId) external view returns (Lot memory);
}