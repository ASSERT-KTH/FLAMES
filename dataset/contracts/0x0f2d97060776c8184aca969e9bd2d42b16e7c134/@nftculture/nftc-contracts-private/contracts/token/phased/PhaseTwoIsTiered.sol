// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-open-contracts
import '@nftculture/nftc-contracts/contracts/utility/AuxHelper32.sol';

// NFTC Prerelease Contracts
import '../../whitelisting/MerkleLeaves.sol';

// NFTC Prerelease Libraries
import {MerkleClaimList} from '../../whitelisting/MerkleClaimList.sol';

error TieredProofInvalid_PhaseTwo();

/**
 * @title PhaseTwoIsTiered
 */
abstract contract PhaseTwoIsTiered is MerkleLeaves, AuxHelper32 {
    using MerkleClaimList for MerkleClaimList.Root;

    MerkleClaimList.Root private _phaseTwoRoot;

    constructor() {}

    function _setPhaseTwoRoot(bytes32 __root) internal {
        _phaseTwoRoot._setRoot(__root);
    }

    function checkProof_PhaseTwo(
        bytes32[] calldata proof,
        address wallet
    ) external view returns (bool) {
        return _phaseTwoRoot._checkLeaf(proof, _generateLeaf(wallet));
    }

    function getTokensPurchased_PhaseTwo(address wallet) external view returns (uint32) {
        (, uint32 phaseTwoPurchases) = _unpack32(_getPackedPurchasesAs64(wallet));
        return phaseTwoPurchases;
    }

    function _getPackedPurchasesAs64(address wallet) internal view virtual returns (uint64);

    function _proofMintTokens_PhaseTwo(
        address minter,
        bytes32[] calldata proof,
        uint256 count
    ) internal {
        // Verify address is eligible for mints in this tier.
        if (!_phaseTwoRoot._checkLeaf(proof, _generateLeaf(minter))) {
            revert TieredProofInvalid_PhaseTwo();
        }

        _internalMintTokens(minter, count);
    }

    function _internalMintTokens(address minter, uint256 count) internal virtual;

    function _proofMintTokensOfFlavor_PhaseTwo(
        address minter,
        bytes32[] calldata proof,
        uint256 count,
        uint256 flavorId
    ) internal {
        // Verify address is eligible for mints in this tier.
        if (!_phaseTwoRoot._checkLeaf(proof, _generateLeaf(minter))) {
            revert TieredProofInvalid_PhaseTwo();
        }

        _internalMintTokens(minter, count, flavorId);
    }

    function _internalMintTokens(address minter, uint256 count, uint256 flavorId) internal virtual;
}
