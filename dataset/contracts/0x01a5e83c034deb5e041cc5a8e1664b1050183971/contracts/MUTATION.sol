// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import ".deps/npm/erc721a/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MUTATION16 is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MutationSupply = 2222;
    uint256 public MutationPrice = 0 ether;
    uint256 public MaxMutationPerWL = 3;
    uint256 public MaxMutationPerPublic = 2;

    bool public PublicMintEnabled = false;
    bool public WhitelistMintEnabled = false;

    bytes32 private merkleRoot;
    mapping(address => bool) public publicClaimed;
    mapping(address => bool) public whitelistClaimed;
    string public uriSuffix = ".json";
    string public baseURI = "";

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC721A(_tokenName, _tokenSymbol)
    {
        _mint(msg.sender, 1);
    }

    function MintWhitelist(uint256 _MUTATIONAmount, bytes32[] memory _proof)
        public
        payable
    {
        uint256 mintedMUTATION = totalSupply();
        require(WhitelistMintEnabled, "The mint isn't open yet");
        require(
            _MUTATIONAmount <= MaxMutationPerWL,
            "Invalid MUTATION amount"
        );
        require(
            mintedMUTATION + _MUTATIONAmount <= MutationSupply,
            "Exceeded supply"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(!whitelistClaimed[msg.sender]);
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof!");
        _mint(msg.sender, _MUTATIONAmount);
        delete mintedMUTATION;
        whitelistClaimed[msg.sender] = true;
    }

    function PublicMint(uint256 _MUTATIONAmount) public payable {
        uint256 mintedMUTATION = totalSupply();
        require(PublicMintEnabled, "The mint isn't open yet");
        require(!publicClaimed[msg.sender], "Address already minted");
        require(
            _MUTATIONAmount <= MaxMutationPerPublic,
            "Invalid nft amount"
        );
        require(
            _MUTATIONAmount + mintedMUTATION <= MutationSupply,
            "Public supply exceeded"
        );
        _mint(msg.sender, _MUTATIONAmount);
        publicClaimed[msg.sender] = true;
        delete mintedMUTATION;
    }

    function adminMint(uint256 _teamAmount) external onlyOwner {
        _mint(msg.sender, _teamAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setWLMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPublicMintStatus(bool _state) public onlyOwner {
        PublicMintEnabled = _state;
    }

    function setWhitelistMintStatus(bool _state) public onlyOwner {
        WhitelistMintEnabled = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function withdrawBalance() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "WITHDRAW FAILED!");
    }
}
