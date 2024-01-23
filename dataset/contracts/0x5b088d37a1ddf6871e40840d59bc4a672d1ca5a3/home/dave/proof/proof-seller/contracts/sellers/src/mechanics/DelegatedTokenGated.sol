// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {IDelegationRegistry} from "delegation-registry/IDelegationRegistry.sol";
import {IERC721, TokenGated} from "./TokenGated.sol";

/**
 * @notice Extension to `ClaimableWithToken` adding delegation via
 * delegate.cash.
 */
abstract contract DelegatedTokenGated is TokenGated {
    /**
     * @notice The delegate.cash delegation registry.
     */
    IDelegationRegistry internal immutable _delegationRegistry;

    constructor(IERC721 token, IDelegationRegistry delegationRegistry) TokenGated(token) {
        _delegationRegistry = delegationRegistry;
    }

    /**
     * @inheritdoc TokenGated
     */
    function _isAllowedToPurchaseWithToken(address operator, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        // Reimplemententing the standard checks instead of calling
        // `super._isAllowedToClaim` here to have a specific ordering for gas
        // efficiency: 1. owner, 2. delegation, 3. ERC721 approvals.
        address tokenOwner = _token.ownerOf(tokenId);
        return (operator == tokenOwner)
            || _delegationRegistry.checkDelegateForToken(operator, tokenOwner, address(_token), tokenId)
            || _token.isApprovedForAll(tokenOwner, operator) || (operator == _token.getApproved(tokenId));
    }
}
