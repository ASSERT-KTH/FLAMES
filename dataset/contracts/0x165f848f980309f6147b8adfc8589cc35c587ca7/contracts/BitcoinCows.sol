
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IDelegationRegistry.sol";

error MaxSupplyReached();
error NotAllowedToMint();
error MaxAmountClaimed();
error NotEnoughPaid();
error PublicNotActive();

contract BitcoinCowsBridge is Ownable {
    // Ethereum Reservation and Verifiable Random Bridge to Bitcoin
    // Ids correspond to all 10k Cows sha256 hashed in the provenanceHash and then shuffled and mapped to event log BTC address order, afterwards the final tokenId will depend on BTC Block Ordering
    // Secure shuffle randomization through Future Block Commitment and hashed secret, which means noone, not even the team or miners, can manipulate the randomness
    uint256 public constant MAX_SUPPLY = 10000;
    // price for allowlist
    uint256 public constant price = 0.006 ether;
    // price for public, if anything remains
    uint256 public publicPrice = 0.02 ether;
    // public sale status
    bool public publicIsActive;
    // reservation counter
    uint256 public totalReserved;
    // team allocation
    uint256 public devReserved;
    // Reservation Event logs in order of ids, starting with 0
    event Reservation(bytes32 btcAddressBech32m, uint256 amount);
    // Ordinal Collection
    string public bitcoinOrdinals;
    // Merkleroot
    bytes32 public merkleRoot;
    // Number of Ordinals reserved to wallets
    mapping(address => uint256) public ordinalsClaimed;
    // SHA-256 concatenation Provenance Hash (public before randomization)
    uint256 public provenanceHash;
    // Commit to a Future Block to create a random seed
    uint256 private revealBlock;
    // Random Seed for Shuffling
    bytes32 public randomSeed;
    // Tokens to be shuffled (revealed after random number is picked by miners, matches the provenanceHash)
    string public sourceURI;
    // Provenance File
    string public provenanceFile;
    // Delegate Cash
    IDelegationRegistry private dc = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    function setProvenanceHash(uint256 _provenanceHash) external onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function setSourceURI(string memory _sourceURI) external onlyOwner {
        sourceURI = _sourceURI;
    }

    function setProvenanceFile(string memory _provenanceFile) external onlyOwner {
        provenanceFile = _provenanceFile;
    }

    function setBitcoinOrdinals(string memory _bitcoinOrdinals) external onlyOwner {
        bitcoinOrdinals = _bitcoinOrdinals;
    }

    function setAllowlist(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function commitRevealBlock() external onlyOwner {
        require(revealBlock==0, "Already committed to a reveal block.");
        revealBlock = block.number + 14;
    }

    function setRandomSeed() external onlyOwner {
        randomSeed = blockhash(revealBlock);
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function togglePublicSale() external onlyOwner {
        publicIsActive = !publicIsActive;
    }

    function allowlistReservation(address _vault, bytes32 btcAddressBech32m, uint256 quantity, uint256 allocation, bytes32[] calldata merkleProof) external payable {
        // Max Supply
        uint256 newTotalReserved = totalReserved + quantity;
        if (newTotalReserved > MAX_SUPPLY) revert MaxSupplyReached();
        // Delegate Cash support
        address requester = msg.sender;
        if (_vault != address(0)) { 
            bool isDelegateValid = dc.checkDelegateForContract(msg.sender, _vault, address(0xBE82b9533Ddf0ACaDdcAa6aF38830ff4B919482C));
            require(isDelegateValid, "invalid delegate-vault pairing");
            requester = _vault;
        }
        // Allocation
        uint256 totalClaimed = quantity+ordinalsClaimed[requester];
        if (totalClaimed > allocation) revert MaxAmountClaimed();
        // Payment
        if (msg.value < price * quantity) revert NotEnoughPaid();
        // Allowlist
        bytes32 leaf = keccak256(abi.encodePacked(requester, allocation));
        if(!MerkleProof.verify(merkleProof, merkleRoot, leaf)) revert NotAllowedToMint();
        // Update Counters
        totalReserved = newTotalReserved;
        ordinalsClaimed[requester] = totalClaimed;
        // Reservation Log
        emit Reservation(btcAddressBech32m, quantity);
    }

    function publicReservation(bytes32 btcAddressBech32m) external payable {
        if (!publicIsActive) revert PublicNotActive();
        if (msg.sender != tx.origin) revert NotAllowedToMint();
        // Max Supply
        if (++totalReserved > MAX_SUPPLY) revert MaxSupplyReached();
        // 1 per wallet
        if (ordinalsClaimed[msg.sender] != 0) revert MaxAmountClaimed();
        // Payment
        if (msg.value < publicPrice) revert NotEnoughPaid();
        // Update Counter
        ++ordinalsClaimed[msg.sender];
        // Reservation Log
        emit Reservation(btcAddressBech32m, 1);
    }

    function devReservation(bytes32[] calldata btcAddressBech32m, uint256 quantity) external onlyOwner {
        // Max Supply
        uint256 totalQuantity = quantity*btcAddressBech32m.length;
        uint256 newTotalReserved = totalReserved + totalQuantity;
        if (newTotalReserved > MAX_SUPPLY) revert MaxSupplyReached();
        // Reservation
        for(uint256 i; i < btcAddressBech32m.length; i++) {
            emit Reservation(btcAddressBech32m[i], quantity);
        }
        // Update Counters
        devReserved+=totalQuantity;
        totalReserved=newTotalReserved;
    }

    function shuffle() external view returns (uint256[] memory) {
        require(provenanceHash!=0, "ERROR");
        bytes32 _randomSeed = randomSeed;
        uint256[] memory permutations = new uint256[](MAX_SUPPLY);
        uint256[] memory result = new uint256[](MAX_SUPPLY);
        uint256 perm;
        uint256 value;
        uint256 index;
        uint256 indexes = MAX_SUPPLY;
        for (uint256 i; i < MAX_SUPPLY; i++) {
            uint256 seed = uint256(keccak256(abi.encodePacked(_randomSeed, i)));
            index = seed % indexes;
            value = permutations[index];
            perm = permutations[indexes - 1];
            result[i] = value == 0 ? index : value - 1;
            permutations[index] = perm == 0 ? indexes : perm;
            indexes--;
        }
        return result;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert();
    }

}