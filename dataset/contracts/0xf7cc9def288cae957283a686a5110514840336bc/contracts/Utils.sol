// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library Utils {
    function tokenCheck(bytes32 root, uint id, bytes32[] calldata keys) internal pure returns (bool) {
        return MerkleProof.verify(keys, root, bytes32(id));
    }
}