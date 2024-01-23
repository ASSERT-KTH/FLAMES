// SPDX-License-Identifier: MIT
// WARNING! This smart contract has not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION
// This is an example contract to demonstrate how to integrate an application with the audited production release of AxiomV1.
pragma solidity 0.8.19;

// Constants and free functions to be inlined into by AxiomV1Core

// ZK circuit constants:

// AxiomV1 caches blockhashes in batches, stored as Merkle roots of binary Merkle trees
uint32 constant BLOCK_BATCH_SIZE = 1024;
uint32 constant BLOCK_BATCH_DEPTH = 10;

// constants for batch import of historical block hashes
// historical uploads a bigger batch of block hashes, stored as Merkle roots of binary Merkle trees
uint32 constant HISTORICAL_BLOCK_BATCH_SIZE = 131072; // 2 ** 17
uint32 constant HISTORICAL_BLOCK_BATCH_DEPTH = 17;
// we will consider the historical Merkle tree of blocks as a Merkle tree of the block batch roots
uint32 constant HISTORICAL_NUM_ROOTS = 128; // HISTORICAL_BATCH_SIZE / BLOCK_BATCH_SIZE

// The first 4 * 3 * 32 bytes of proof calldata are reserved for two BN254 G1 points for a pairing check
// It will then be followed by (7 + BLOCK_BATCH_DEPTH * 2) * 32 bytes of public inputs/outputs
uint32 constant AUX_PEAKS_START_IDX = 608; // PUBLIC_BYTES_START_IDX + 7 * 32

// Historical MMR Ring Buffer constants
uint32 constant MMR_RING_BUFFER_SIZE = 8;

/// @dev proofData stores bytes32 and uint256 values in hi-lo format as two uint128 values because the BN254 scalar field is 254 bits
/// @dev The first 12 * 32 bytes of proofData are reserved for ZK proof verification data
// Extract public instances from proof
// The public instances are laid out in the proof calldata as follows:
// First 4 * 3 * 32 = 384 bytes are reserved for proof verification data used with the pairing precompile
// 384..384 + 32 * 2: prevHash (32 bytes) as two uint128 cast to uint256, because zk proof uses 254 bit field and cannot fit uint256 into a single element
// 384 + 32 * 2..384 + 32 * 4: endHash (32 bytes) as two uint128 cast to uint256
// 384 + 32 * 4..384 + 32 * 5: startBlockNumber (uint32: 4 bytes) and endBlockNumber (uint32: 4 bytes) are concatenated as `startBlockNumber . endBlockNumber` (8 bytes) and then cast to uint256
// 384 + 32 * 5..384 + 32 * 7: root (32 bytes) as two uint128 cast to uint256, this is the highest peak of the MMR if endBlockNumber - startBlockNumber == 1023, otherwise 0
function getBoundaryBlockData(bytes calldata proofData)
    pure
    returns (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32 root)
{
    prevHash = bytes32(uint256(bytes32(proofData[384:416])) << 128 | uint256(bytes32(proofData[416:448])));
    endHash = bytes32(uint256(bytes32(proofData[448:480])) << 128 | uint256(bytes32(proofData[480:512])));
    startBlockNumber = uint32(bytes4(proofData[536:540]));
    endBlockNumber = uint32(bytes4(proofData[540:544]));
    root = bytes32(uint256(bytes32(proofData[544:576])) << 128 | uint256(bytes32(proofData[576:608])));
}

// We have a Merkle mountain range of max depth BLOCK_BATCH_DEPTH (so length BLOCK_BATCH_DEPTH + 1 total) ordered in **decreasing** order of peak size, so:
// `root` from `getBoundaryBlockData` is the peak for depth BLOCK_BATCH_DEPTH
// `getAuxMmrPeak(proofData, i)` is the peaks for depth BLOCK_BATCH_DEPTH - 1 - i
// 384 + 32 * 7 + 32 * 2 * i .. 384 + 32 * 7 + 32 * 2 * (i + 1): (32 bytes) as two uint128 cast to uint256, same as blockHash
// Note that the decreasing ordering is *different* than the convention in library MerkleMountainRange
function getAuxMmrPeak(bytes calldata proofData, uint256 i) pure returns (bytes32) {
    return bytes32(
        uint256(bytes32(proofData[AUX_PEAKS_START_IDX + i * 64:AUX_PEAKS_START_IDX + i * 64 + 32])) << 128
            | uint256(bytes32(proofData[AUX_PEAKS_START_IDX + i * 64 + 32:AUX_PEAKS_START_IDX + (i + 1) * 64]))
    );
}

interface IAxiomV1Verifier {
    /// @notice A merkle proof to verify a block against the verified blocks cached by Axiom
    /// @dev    `BLOCK_BATCH_DEPTH = 10`
    struct BlockHashWitness {
        uint32 blockNumber;
        bytes32 claimedBlockHash;
        bytes32 prevHash;
        uint32 numFinal;
        bytes32[BLOCK_BATCH_DEPTH] merkleProof;
    }

    /// @notice Verify the blockhash of block blockNumber equals claimedBlockHash. Assumes that blockNumber is within the last 256 most recent blocks.
    /// @param  blockNumber The block number to verify
    /// @param  claimedBlockHash The claimed blockhash of block blockNumber
    function isRecentBlockHashValid(uint32 blockNumber, bytes32 claimedBlockHash) external view returns (bool);

    /// @notice Verify the blockhash of block witness.blockNumber equals witness.claimedBlockHash by checking against Axiom's cache of #historicalRoots.
    /// @dev    For block numbers within the last 256, use #isRecentBlockHashValid instead.
    /// @param  witness The block hash to verify and the Merkle proof to verify it
    ///         witness.blockNumber is the block number to verify
    ///         witness.claimedBlockHash is the claimed blockhash of block witness.blockNumber
    ///         witness.prevHash is the prevHash stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.numFinal is the numFinal stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.merkleProof is the Merkle inclusion proof of witness.claimedBlockHash to the root stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.merkleProof[i] is the sibling of the Merkle node at depth 10 - i, for i = 0, ..., 10
    function isBlockHashValid(BlockHashWitness calldata witness) external view returns (bool);

    /// @notice Verify the blockhash of block blockNumber equals claimedBlockHash by checking against Axiom's cache of historical Merkle mountain ranges in #mmrRingBuffer.
    /// @dev    Use event logs to determine the correct bufferId and get the MMR at that index in the ring buffer.
    /// @param  mmr The Merkle mountain range commited to in #mmrRingBuffer(bufferId), must be correct length
    /// @param  bufferId The index in the ring buffer of #mmrRingBuffer
    /// @param  blockNumber The block number to verify
    /// @param  claimedBlockHash The claimed blockhash of block blockNumber
    /// @param  merkleProof The Merkle inclusion proof of claimedBlockHash to the corresponding peak in mmr. The correct peak is calculated from mmr.length and blockNumber.
    function mmrVerifyBlockHash(
        bytes32[] calldata mmr,
        uint8 bufferId,
        uint32 blockNumber,
        bytes32 claimedBlockHash,
        bytes32[] calldata merkleProof
    ) external view;
}

interface IAxiomV1Update {
    /// @notice Verify and store a batch of consecutive blocks, where the latest block in the batch is within the last 256 most recent blocks.
    /// @param  proofData The raw bytes of a zero knowledge proof to be verified by the contract.
    ///         proofData contains public inputs/outputs of
    ///         (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32[11] mmr)
    ///         where the proof verifies the blockhashes of blocks [startBlockNumber, endBlockNumber], endBlockNumber - startBlockNumber <= 1023
    ///         - startBlockNumber must be a multiple of 1024
    ///         - prevHash is the parent hash of block `startBlockNumber`,
    ///         - endHash is the blockhash of block `endBlockNumber`,
    ///         - mmr is the keccak Merkle mountain range of the blockhashes of blocks [startBlockNumber, endBlockNumber], ordered from depth 10 to depth 0
    function updateRecent(bytes calldata proofData) external;

    /// @notice Verify and store a batch of 1024 consecutive blocks,
    ///         where the latest block in the batch is verified against the blockhash cache in #historicalRoots
    /// @dev    The contract checks that #historicalRoots(endBlockNumber + 1) == keccak256(endHash || nextRoot || nextNumFinal)
    ///         where endBlockNumber, endHash are derived from proofData.
    ///         nextRoot and nextNumFinal should be obtained by reading event logs. For old blocks nextNumFinal is _usually_ 1024.
    /// @param  proofData The raw bytes of a zero knowledge proof to be verified by the contract. Has same format as in #updateRecent except
    ///         endBlockNumber = startBlockNumber + 1023, so the block batch size is exactly 1024
    ///         mmr contains the keccak Merkle root of the full Merkle tree of depth 10, followed by zeros
    /// @param  nextRoot The Merkle root stored in #historicalRoots(endBlockNumber + 1)
    /// @param  nextNumFinal The numFinal stored in #historicalRoots(endBlockNumber + 1)
    function updateOld(bytes32 nextRoot, uint32 nextNumFinal, bytes calldata proofData) external;

    /// @notice Verify and store a batch of 2^17 = 128 * 1024 consecutive blocks,
    ///         where the latest block in the batch is verified against the blockhash cache in #historicalRoots
    /// @dev    Has the same effect as calling #updateOld 128 times on consecutive batches of 1024 blocks each.
    ///         But uses a different SNARK to verify the proof of all 2^17 blocks at once.
    ///         endHashProofs is used to get the intermediate parent hashes of these 1024 block batches
    /// @param  proofData The raw bytes of a zero knowledge proof to be verified by the contract. Has similar format as in #updateRecent except
    ///         we require endBlockNumber = startBlockNumber + 2^17 - 1, so the block batch size is exactly 2^17.
    ///         proofData contains public inputs/outputs of:
    ///         (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32[18] mmr)
    ///         - startBlockNumber must be a multiple of 1024
    ///         - we require that endBlockNumber - startBlockNumber = 2^17 - 1
    ///         - prevHash is the parent hash of block `startBlockNumber`,
    ///         - endHash is the blockhash of block `endBlockNumber`,
    ///         - mmr[0] is the keccak Merkle root of the blockhashes of blocks [startBlockNumber, startBlockNumber + 2^17), the other entries in mmr are zeros
    /// @param  nextRoot The Merkle root stored in #historicalRoots(endBlockNumber + 1)
    /// @param  nextNumFinal The numFinal stored in #historicalRoots(endBlockNumber + 1)
    /// @param  roots roots[i] is the Merkle root of the blockhashes of blocks [startBlockNumber + i * 1024, startBlockNumber + (i + 1) * 1024) for i = 0, ..., 127
    /// @param  endHashProofs endHashProofs[i] is the Merkle inclusion proof of the blockhash of block `startBlockNumber + (i + 1) * 1024 - 1` in roots[i], for i = 0, ..., 126
    ///         endHashProofs[i][10] is the blockhash of block `startBlockNumber + (i + 1) * 1024 - 1`
    ///         endHashProofs[i][j] is the sibling of the Merkle node at depth j, for j = 0, ..., 9
    function updateHistorical(
        bytes32 nextRoot,
        uint32 nextNumFinal,
        bytes32[128] calldata roots,
        bytes32[11][127] calldata endHashProofs,
        bytes calldata proofData
    ) external;

    /// @notice Extended the stored historical Merkle Mountain Range with a multiple of 1024 blockhash commitments
    /// @dev    The blocks to append must have already been cached by Axiom.
    ///         startBlockNumber must equal historicalMMR.len * 1024, but we make it an input for faster reverts
    /// @param  startBlockNumber The block number of the first block to append
    /// @param  roots roots[i] is the Merkle root of the blockhashes of blocks [startBlockNumber + i * 1024, startBlockNumber + (i + 1) * 1024) for i = 0, ..., roots.length - 1
    /// @param  prevHashes prevHashes[i] is the parent hash of block `startBlockNumber + i * 1024`, for i = 0, ..., roots.length - 1. prevHashes and roots must have the same length.
    function appendHistoricalMMR(uint32 startBlockNumber, bytes32[] calldata roots, bytes32[] calldata prevHashes)
        external;
}

interface IAxiomV1State {
    /// @notice Returns the hash of a batch of consecutive blocks previously verified by the contract
    /// @dev    The reads here will match the emitted #UpdateEvent
    /// @return historicalRoots(startBlockNumber) is 0 unless (startBlockNumber % 1024 == 0)
    ///         historicalRoots(startBlockNumber) = 0 if block `startBlockNumber` is not verified
    ///         historicalRoots(startBlockNumber) = keccak256(prevHash || root || numFinal) where || is concatenation
    ///         - prevHash is the parent hash of block `startBlockNumber`
    ///         - root is the keccak Merkle root of hash(i) for i in [0, 1024), where
    ///             hash(i) is the blockhash of block `startBlockNumber + i` if i < numFinal,
    ///             hash(i) = bytes32(0x0) if i >= numFinal
    ///         - 0 < numFinal <= 1024 is the number of verified consecutive roots in [startBlockNumber, startBlockNumber + numFinal)
    function historicalRoots(uint32 startBlockNumber) external view returns (bytes32);

    /// @notice Returns metadata about the number of consecutive blocks from genesis stored in the contract
    ///         The Merkle mountain range stores a commitment to the variable length list where `list[i]` is the Merkle root of the binary tree with leaves the blockhashes of blocks [1024 * i, 1024 * (i + 1))
    /// @return numPeaks = bit_length(len) is the number of peaks in the Merkle mountain range
    /// @return len indicates that the historicalMMR commits to blockhashes of blocks [0, 1024 * len)
    /// @return index the current index in the ring buffer storing commitments to historicalMMRs
    function historicalMMR() external view returns (uint32 numPeaks, uint32 len, uint32 index);

    /// @notice Returns the i-th Merkle root in the historical Merkle Mountain Range
    /// @param  i The index, `peaks[i] = root(list[((len >> i) << i) - 2^i : ((len >> i) << i)])` if 2^i & len != 0, otherwise 0
    ///         where root(single element) = single element,
    ///         list is the variable length list where `list[i]` is the Merkle root of the binary tree with leaves the blockhashes of blocks [1024 * i, 1024 * (i + 1))
    function historicalMMRPeaks(uint32 i) external view returns (bytes32);

    /// @notice A ring buffer storing commitments to past historicalMMR states
    /// @param  index The index in the ring buffer
    function mmrRingBuffer(uint256 index) external view returns (bytes32);
}

interface IAxiomV1Events {
    /// @notice Emitted when a new batch of consecutive blocks is trustlessly verified and cached in the contract storage `historicalRoots`
    /// @param  startBlockNumber The block number of the first block in the batch
    /// @param  prevHash The parent hash of block `startBlockNumber`
    /// @param  root The Merkle root of hash(i) for i in [0, 1024), where hash(i) is the blockhash of block `startBlockNumber + i` if i < numFinal,
    ///              Otherwise hash(i) = bytes32(0x0) if i >= numFinal
    /// @param  numFinal The number of consecutive blocks in this batch, i.e., [startBlockNumber, startBlockNumber + numFinal) blocks are verified
    event UpdateEvent(uint32 startBlockNumber, bytes32 prevHash, bytes32 root, uint32 numFinal);

    /// @notice Emitted when the size of the historicalMMR changes.
    /// @param  len The historicalMMR now stores commitment to blocks [0, 1024 * len)
    /// @param  index The new index in the ring buffer storing the commitment to historicalMMR
    event MerkleMountainRangeEvent(uint32 len, uint32 index);

    /// @notice Emitted when the SNARK #verifierAddress changes
    /// @param  newAddress The new address of the SNARK verifier contract
    event UpgradeSnarkVerifier(address newAddress);

    /// @notice Emitted when the SNARK #historicalVerifierAddress changes
    /// @param  newAddress The new address of the SNARK historical verifier contract
    event UpgradeHistoricalSnarkVerifier(address newAddress);
}

/// @title The interface for the core Axiom V1 contract
/// @notice The Axiom V1 contract stores a continually updated cache of all historical block hashes
/// @dev The interface is broken up into many smaller pieces
interface IAxiomV1 is IAxiomV1Events, IAxiomV1State, IAxiomV1Update, IAxiomV1Verifier {}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Original source @ https://github.com/hamdiallam/Solidity-RLP.

/**
 * @author Hamdi Allam hamdi.allam97@gmail.com
 * Please reach out with any questions or concerns
 */

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param the RLP item.
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @param the RLP item.
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        (, uint256 len) = payloadLocation(item);
        return len;
    }

    /*
     * @param the RLP item containing the encoded list.
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /**
     * RLPItem conversions into data types *
     */

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        (uint256 memPtr, uint256 len) = payloadLocation(item);

        uint256 result;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) { result := div(result, exp(256, sub(32, len))) }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            itemLen = 1;
        } else if (byte0 < STRING_LONG_START) {
            itemLen = byte0 - STRING_SHORT_START + 1;
        } else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            return 0;
        } else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) {
            return 1;
        } else if (byte0 < LIST_SHORT_START) {
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        } else {
            return byte0 - (LIST_LONG_START - 1) + 1;
        }
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(uint256 src, uint256 dest, uint256 len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint256 mask = 256 ** (WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}

contract Randao is Ownable {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    address public axiomAddress;
    uint32 public mergeBlock;

    // mapping between blockNumber and prevRandao
    mapping(uint32 => uint256) public prevRandaos;

    event RandaoProof(uint32 blockNumber, uint256 prevRandao);

    event UpdateAxiomAddress(address newAddress);

    constructor(address _axiomAddress, uint32 _mergeBlock) {
        axiomAddress = _axiomAddress;
        mergeBlock = _mergeBlock;
        emit UpdateAxiomAddress(_axiomAddress);
    }

    function updateAxiomAddress(address _axiomAddress) external onlyOwner {
        axiomAddress = _axiomAddress;
        emit UpdateAxiomAddress(_axiomAddress);
    }

    function verifyRandao(IAxiomV1.BlockHashWitness calldata witness, bytes calldata header) external {
        if (block.number - witness.blockNumber <= 256) {
            require(
                IAxiomV1(axiomAddress).isRecentBlockHashValid(witness.blockNumber, witness.claimedBlockHash),
                "Block hash was not validated in cache"
            );
        } else {
            require(IAxiomV1(axiomAddress).isBlockHashValid(witness), "Block hash was not validated in cache");
        }

        require(witness.blockNumber > mergeBlock, "prevRandao is not valid before merge block");

        RLPReader.RLPItem[] memory headerItems = header.toRlpItem().toList();
        uint256 prevRandao = headerItems[13].toUint();

        prevRandaos[witness.blockNumber] = prevRandao;
        emit RandaoProof(witness.blockNumber, prevRandao);
    }
}

