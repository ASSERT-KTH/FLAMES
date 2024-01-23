// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 * @dev Implementation of the EPS ERC1155 Delegation register interface.
 *
 */
interface IERC1155DelegateRegister {
  function getBeneficiaryByRight(
    address tokenContract_,
    uint256 tokenId_,
    uint256 rightsIndex_
  ) external view returns (address);

  function getBalanceByRight(
    address tokenContract_,
    uint256 tokenId_,
    address queryAddress_,
    uint256 rightsIndex_
  ) external view returns (uint256);

  function getAllAddressesByRightsIndex(
    address receivedAddress_,
    uint256 rightsIndex_,
    address coldAddress_,
    bool includeReceivedAndCold_
  ) external view returns (address[] memory containers_);

  function containerToDelegationId(address container_)
    external
    view
    returns (uint64 delegationId_);
}
