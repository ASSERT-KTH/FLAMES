// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IKookyKats.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KookyKatsSale is Ownable, Pausable, ReentrancyGuard {
    enum MINT_ROUNDS {
        NONE,
        WHITELIST_PAID_MINT,
        WHITELIST_FREE_MINT,
        PUBLIC_PAID_MINT
    }

    bytes32 public FREE_MINT_WHITELIST;

    bytes32 public PAID_MINT_WHITELIST;

    /// @dev Current ongoing mint round Id
    MINT_ROUNDS public ROUND_ID;

    /// @dev Max LLC amount per person in each round
    uint16 public MAX_MINT_AMOUNT;

    /// @dev Reserved amount for free minting whitelist
    uint16 public RESERVED_MINT_AMOUNT;

    /// @dev Ignore reserved amount
    bool public IGNORE_RESERVED_AMOUNT;

    /// @dev KookyKats NFT contract
    IKookyKats public KOOKY_KATS;

    /// @dev Fee for minting KookyKats NFT
    uint256 public MINT_FEE;

    /// @dev Minting participants data per minting round
    mapping(MINT_ROUNDS => mapping(address => uint256)) public participants;

    constructor(address kat) {
        setKookyKats(kat);
        _pause();
    }

    /// @dev Set free mint whitelist merkleroot
    function setFreeMintWhitelist(bytes32 root) external onlyOwner {
        FREE_MINT_WHITELIST = root;
    }

    /// @dev Set paid mint whitelist merkleroot
    function setPaidMintWhitelist(bytes32 root) external onlyOwner {
        PAID_MINT_WHITELIST = root;
    }

    /// @dev Set reserved minting amount
    function setReservedAmount(uint16 amount) external onlyOwner {
        RESERVED_MINT_AMOUNT = amount;
    }

    /// @dev Set KookyKats NFT contract address
    function setKookyKats(address kat) public onlyOwner {
        KOOKY_KATS = IKookyKats(kat);
        emit SetKookyKats(kat);
    }

    function setIgnoreReservedAmount() public onlyOwner {
        IGNORE_RESERVED_AMOUNT = !IGNORE_RESERVED_AMOUNT;
    }

    /// @dev Open new mint phrase
    function openMintRound(
        MINT_ROUNDS roundId,
        uint16 maxAmount,
        uint256 fee
    ) external onlyOwner {
        require(
            ROUND_ID == MINT_ROUNDS.NONE,
            "KookyKatsSale: Close ongoing mint round first"
        );
        require(
            roundId != MINT_ROUNDS.NONE,
            "KookyKatsSale: Invalid minting roundId"
        );
        require(maxAmount > 0, "KookyKatsSale: Invalid max amount");
        ROUND_ID = roundId;
        MAX_MINT_AMOUNT = maxAmount;
        MINT_FEE = fee;
        emit MintRoundOpend(roundId, maxAmount, fee);
    }

    /// @dev Close mint phrase
    function closeMintRound() external onlyOwner {
        require(
            ROUND_ID != MINT_ROUNDS.NONE,
            "KookyKatsSale: No ongoing mint round"
        );
        ROUND_ID = MINT_ROUNDS.NONE;
        MAX_MINT_AMOUNT = 0;
        MINT_FEE = 0;
        emit MintRoundClosed();
    }

    /// @dev Pause minting
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause minting
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Withdraw funds from contract
    function withdraw(address to) external onlyOwner {
        payable(to).transfer(payable(address(this)).balance);
    }

    function mint(
        bytes32[] calldata proofs,
        uint256 amount
    ) external payable nonReentrant whenNotPaused {
        require(
            ROUND_ID != MINT_ROUNDS.NONE,
            "KookyKatsSale: No ongoing minting round"
        );
        require(amount > 0, "KookyKatsSale: Invalid mint amount");

        uint256 fee = MINT_FEE * amount;
        require(msg.value == fee, "KookyKatsSale: Invalid minting fee");

        uint256 mintedAmount = participants[ROUND_ID][_msgSender()] + amount;
        require(mintedAmount <= MAX_MINT_AMOUNT, "KookyKatsSale: Overflow");

        if (ROUND_ID != MINT_ROUNDS.PUBLIC_PAID_MINT) {
            bytes32 whitelist = ROUND_ID == MINT_ROUNDS.WHITELIST_FREE_MINT
                ? FREE_MINT_WHITELIST
                : PAID_MINT_WHITELIST;
            require(
                MerkleProof.verify(
                    proofs,
                    whitelist,
                    keccak256(abi.encodePacked(_msgSender()))
                ),
                "KookyKatsSale: Only whitelisted users can participate"
            );
        }

        if (ROUND_ID != MINT_ROUNDS.WHITELIST_FREE_MINT) {
            uint256 maxSupply = KOOKY_KATS.MAX_SUPPLY();
            uint256 totalSupply = KOOKY_KATS.totalSupply();

            if (!IGNORE_RESERVED_AMOUNT) {
                maxSupply -= RESERVED_MINT_AMOUNT;
            }

            require(totalSupply + amount <= maxSupply, "KookyKatsSale: Overflowed");
        }

        KOOKY_KATS.mint(_msgSender(), amount);
        participants[ROUND_ID][_msgSender()] = mintedAmount;
        emit Participated(ROUND_ID, _msgSender(), amount);
    }

    event Whitelisted(bytes32 indexed root);

    event SetKookyKats(address indexed kookykats);

    event MintRoundOpend(MINT_ROUNDS roundId, uint16 maxAmount, uint256 fee);

    event MintRoundClosed();

    event Participated(
        MINT_ROUNDS roundId,
        address indexed who,
        uint256 amount
    );
}
