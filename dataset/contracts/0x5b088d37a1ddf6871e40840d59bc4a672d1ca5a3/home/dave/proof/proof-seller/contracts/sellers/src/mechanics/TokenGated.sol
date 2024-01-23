// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {BitMaps} from "openzeppelin-contracts/utils/structs/BitMaps.sol";
import {SafeCast} from "openzeppelin-contracts/utils/math/SafeCast.sol";
import {ExactInternallyPriced, InternallyPriced} from "../base/InternallyPriced.sol";

/**
 * @notice Introduces claimability based on ERC721 token ownership.
 */
abstract contract TokenGated is InternallyPriced {
    using BitMaps for BitMaps.BitMap;

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if the caller is not allowed to act with a given token.
     */
    error CallerNotAllowedToPurchaseWithToken(address caller, uint256 tokenId);

    /**
     * @notice Thrown if a token was already used to claim.
     */
    error TokenAlreadyUsedForPurchase(uint256 tokenId);

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The ERC721 contract for token-gating.
     */
    IERC721 internal immutable _token;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Keeps track of tokens that have already been used for
     * redemptions.
     */
    BitMaps.BitMap private _usedTokens;

    constructor(IERC721 token) {
        _token = token;
    }

    // =========================================================================
    //                           Claiming
    // =========================================================================

    /**
     * @notice Checks if a token has already been used to claim.
     */
    function alreadyPurchasedWithTokens(uint256[] calldata tokenIds) external view returns (bool[] memory) {
        bool[] memory used = new bool[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; ++i) {
            used[i] = _usedTokens.get(tokenIds[i]);
        }
        return used;
    }

    /**
     * @notice Redeems claims with a list of given token ids.
     * @dev Reverts if the sender is not allowed to spend one or more of the
     * listed tokens or if a token has already been used.
     */
    function purchase(uint256[] calldata tokenIds) external payable virtual {
        for (uint256 i; i < tokenIds.length; ++i) {
            if (!_isAllowedToPurchaseWithToken(msg.sender, tokenIds[i])) {
                revert CallerNotAllowedToPurchaseWithToken(msg.sender, tokenIds[i]);
            }

            if (_usedTokens.get(tokenIds[i])) {
                revert TokenAlreadyUsedForPurchase(tokenIds[i]);
            }
            _usedTokens.set(tokenIds[i]);
        }

        InternallyPriced._purchase(msg.sender, SafeCast.toUint64(tokenIds.length), "");
    }

    /**
     * @notice Determines if a given operator is allowed to claim from a given
     * token.
     * @dev by default either the token owner or ERC721 approved operators.
     */
    function _isAllowedToPurchaseWithToken(address operator, uint256 tokenId) internal view virtual returns (bool) {
        address tokenOwner = _token.ownerOf(tokenId);
        return (operator == tokenOwner) || _token.isApprovedForAll(tokenOwner, operator)
            || (operator == _token.getApproved(tokenId));
    }
}
