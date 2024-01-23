
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ███╗   ███╗██╗   ██╗ ██████╗██╗  ██╗ █████╗ ██╗  ██╗██╗   ██╗
// ████╗ ████║██║   ██║██╔════╝██║  ██║██╔══██╗██║ ██╔╝██║   ██║
// ██╔████╔██║██║   ██║╚█████╗ ███████║██║  ██║█████═╝ ██║   ██║
// ██║╚██╔╝██║██║   ██║ ╚═══██╗██╔══██║██║  ██║██╔═██╗ ██║   ██║
// ██║ ╚═╝ ██║╚██████╔╝██████╔╝██║  ██║╚█████╔╝██║ ╚██╗╚██████╔╝
// ╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝ ╚════╝ ╚═╝  ╚═╝ ╚═════╝

contract MushokuNFT is ERC721A, Pausable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant WL_LIMIT_PER_WALLET = 2;
    uint256 public constant PUBLIC_LIMIT_PER_WALLET = 2;
    uint256 public constant OG_LIMIT_PER_WALLET = 1;

    uint256 public constant MAX_SUPPLY = 999;
    // reserved for team and OG
    uint256 public reserved = 333;
    uint256 public reservedForTeam = 40;

    uint256 public wlPrice = 0.019 ether;
    uint256 public publicPrice = 0.029 ether;

    bool public isWlActive = false;
    bool public isPublicActive = false;
    bool public isOgActive = false;

    string private unrevealedUri;
    string private baseURI;
    bool public isRevealed = false;

    bytes32 public wlMerkleRoot;
    bytes32 public ogMerkleRoot;
    mapping(address => uint256) public wlClaimedList;
    mapping(address => uint256) public ogClaimedList;
    mapping(address => uint256) public publicClaimedList;

    constructor(
        string memory _unrevealedUri
    ) ERC721A("MushokuNFT", "MSN") {
        unrevealedUri = _unrevealedUri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function whiteListMint(uint256 _quantity, bytes32[] calldata _merkleProof)
    external
    payable
    whenNotPaused
    {
        require(isWlActive, "Wl phase is not active");
        require(_quantity > 0, "Quantity can't be below zero");
        require(_quantity <= WL_LIMIT_PER_WALLET, "Quantity can't be more two");
        require(
            totalSupply() + _quantity <= MAX_SUPPLY - reserved,
            "Already minted max in wl phase"
        );
        require(msg.value == wlPrice * _quantity, "Mint cost is incorrect");
        require(
            wlClaimedList[msg.sender] + _quantity <= WL_LIMIT_PER_WALLET,
            "You already minted max amount"
        );
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
    require(
            MerkleProof.verify(_merkleProof, wlMerkleRoot, sender) ||
            MerkleProof.verify(_merkleProof, ogMerkleRoot, sender),
            "Invalid merkle proof"
        );
        _safeMint(msg.sender, _quantity);
        wlClaimedList[msg.sender] += _quantity;
    }

    function OgMint(uint256 _quantity, bytes32[] calldata _merkleProof)
    external
    whenNotPaused
    {
        require(isOgActive, "Og phase is not active");
        require(_quantity == OG_LIMIT_PER_WALLET, "Quantity isn't equal to one");
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Already minted max in og"
        );
        require(
            ogClaimedList[msg.sender] + _quantity <= OG_LIMIT_PER_WALLET,
            "You already minted max amount"
        );
        require(
            MerkleProof.verify(
                _merkleProof,
                ogMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "invalid merkle proof"
        );
        _safeMint(msg.sender, _quantity);
        ogClaimedList[msg.sender] += _quantity;
    }

    function publicMint(uint256 _quantity) external payable whenNotPaused {
        require(isPublicActive, "Public phase is not active");
        require(_quantity > 0, "Quantity can't be below zero");
        require(_quantity <= PUBLIC_LIMIT_PER_WALLET, "Quantity can't be more two");
        require(msg.value == publicPrice * _quantity, "Mint cost is incorrect");
        require(
            totalSupply() + _quantity <= MAX_SUPPLY - reserved,
            "Already minted max in public phase"
        );
        require(
            publicClaimedList[msg.sender] + _quantity <=
            PUBLIC_LIMIT_PER_WALLET,
            "You already minted max amount in public"
        );
        _safeMint(msg.sender, _quantity);
        publicClaimedList[msg.sender] += _quantity;
    }

    // for team, it calls before other phases (wl, public, og)
    function reservedForTeamMint(uint256 _quantity)
    external
    onlyOwner
    {
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Can't mint more max supply"
        );
        require(_quantity > 0, "Quantity can't be below zero");
        require(_quantity <= reservedForTeam, "Minted max");
        _safeMint(msg.sender, reservedForTeam);
        reservedForTeam -= _quantity;
        reserved -= _quantity;
    }

    // set phases
    function setIsWlActive(bool _value) external onlyOwner {
        isWlActive = _value;
    }

    function setIsPublicActive(bool _value) external onlyOwner {
        isPublicActive = _value;
    }

    function setIsOgActive(bool _value) external onlyOwner {
        isOgActive = _value;
    }

    // set prices
    function setWlPrice(uint256 _wlPrice) external onlyOwner {
        wlPrice = _wlPrice;
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    // set merkle roots
    function setWlRoot(bytes32 _wlRoot) external onlyOwner {
        wlMerkleRoot = _wlRoot;
    }

    function setOgRoot(bytes32 _ogRoot) external onlyOwner {
        ogMerkleRoot = _ogRoot;
    }

    // withdraw
    function withdraw() external onlyOwner nonReentrant {
        (bool success,) = payable(owner()).call{value : address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function reveal() external onlyOwner {
        isRevealed = true;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setUnrevealedUri(string memory _uri) external onlyOwner {
        unrevealedUri = _uri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if  (isRevealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
        }
        return unrevealedUri;
    }
}
