//
//  ██    ██ ██       █████  ███    ██ ██████       ██  ██████
//  ██    ██ ██      ██   ██ ████   ██ ██   ██      ██ ██    ██
//  ██    ██ ██      ███████ ██ ██  ██ ██   ██      ██ ██    ██
//  ██    ██ ██      ██   ██ ██  ██ ██ ██   ██      ██ ██    ██
//   ██████  ███████ ██   ██ ██   ████ ██████   ██  ██  ██████
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// @title ULAND Heroes dApp / uland.io
// @author 57pixels@uland.io
// @whitepaper https://uland.io/Whitepaper.pdf
// @url https://heroes.uland.io/

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev Uland NFT Interface
 */
interface IULANDHeroesNFT {
    function mint(address to) external;
    function mintId(uint256 tokenId, address to) external;
}

contract ULANDHeroesDapp is Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    bool public paused = false;    
    mapping(string => bool) public _usedNonces;

    uint256 public mintCounter;
    uint256 public mintLimit;
    uint256 public nextTokenId; // Counter to keep track of the next token ID to use

    IULANDHeroesNFT public _ulandHeroNFT;
    address public marketingWallet = 0x3B3E40522ba700a0c2E9030431E5e7fD9af28775; // $ULAND Marketing wallet
    address public signerAddress;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused,"PAUSED");
        _;
    }

    constructor(address _ulandHeroesNFTAddress, address _signerAddress, uint256 _nextTokenId) {
        _ulandHeroNFT = IULANDHeroesNFT(_ulandHeroesNFTAddress);
        signerAddress = _signerAddress;
        nextTokenId = _nextTokenId;
        mintCounter = 0;
        mintLimit = 3333;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure returns (string memory) {
        return "ULAND HEROES DAPP";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
        return "UHD";
    }

    /**
     * @dev Mint functions
     */
    function mint(
        uint256 amount,
        uint256 validTo,
        uint8 qty,
        string memory nonce,
        bytes32 hash,
        bytes memory signature
    ) external payable whenNotPaused {
        require(!_usedNonces[nonce], "NONCE REUSED");
        require(block.timestamp <= validTo, "EXPIRED");
        require(msg.value >= amount, "AMOUNT_TOO_LOW");
        require(mintCounter+qty <= mintLimit, "MINT EXHAUSTED");
        
        bytes32 _hash = keccak256(
            abi.encodePacked(amount, validTo, qty, msg.sender, nonce)
        );

        require(_hash == hash, "INVALID HASH");
        require(matchSigner(hash, signature) == true, "INVALID SIG");

        _usedNonces[nonce] = true;

        for (uint256 i = 1; i <= qty; i++) {
            _ulandHeroNFT.mintId(nextTokenId, msg.sender);
            nextTokenId++;
            mintCounter++;
        }
       
        emit Mint(msg.sender, nonce, qty);
    }

    /**
     * @dev Pay function
     */
    function pay(
        uint256 amount,
        uint256 validTo,
        string memory nonce,
        bytes32 hash,
        bytes memory signature
    ) external payable whenNotPaused {
        require(!_usedNonces[nonce], "NONCE REUSED");
        require(block.timestamp <= validTo, "EXPIRED");
        require(msg.value >= amount, "AMOUNT_TOO_LOW");

        bytes32 _hash = keccak256(
            abi.encodePacked(amount, validTo, msg.sender, nonce)
        );
        require(_hash == hash, "INVALID HASH");
        require(matchSigner(hash, signature) == true, "INVALID SIG");

        _usedNonces[nonce] = true;
        emit Pay(msg.sender, nonce, amount);
    }
    
    /**
     * @dev Validate signature
     */
    function matchSigner(bytes32 hash, bytes memory signature)
        public
        view
        returns (bool)
    {
        return
            signerAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    function getCounters() external view virtual returns (uint256,uint256)
    {
        return (mintCounter, mintLimit);
    }

    
    /*
	 * onlyOwner functions
	 */

	function setSignerAddress(address _signerAddress) public onlyOwner {
		signerAddress = _signerAddress;
	}

    function setNFTAddress(address _nftAddress) public onlyOwner {
		_ulandHeroNFT = IULANDHeroesNFT(_nftAddress);
	}

    function setPause(bool _paused) public onlyOwner {
		paused = _paused;
	}

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
		marketingWallet = _marketingWallet;
	}

    function setNextTokenId(uint256 _nextTokenId)
        public
        onlyOwner
    {
        nextTokenId = _nextTokenId;
    }

    function setCounters(uint256 _mintCounter, uint256 _mintLimit)
        public
        onlyOwner
    {
        mintCounter = _mintCounter;
        mintLimit = _mintLimit;
    }

    /**
     * @dev Withdraw funds to treasury
     */
    function treasuryWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /*
	 * Events
	 */

    event Pay(address sender, string trxid, uint256 amount);
    event Mint(address sender, string trxid, uint8 qty);
}
