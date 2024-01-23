// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCore.sol";
import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SuperJobChangeTicket2023Summer is DefaultOperatorFilterer, EIP2981RoyaltyOverrideCore, ERC721AntiScam, AccessControl, Pausable  {
    // Manage
    bytes32 public constant ADMIN = "ADMIN";

    // Metadata
    string public baseURI;
    string public usedSuffix = '_used';
    string public baseExtension = '.json';

    // Mint
    mapping(address => uint256) public mintedAmount;
    bytes32 merkleRoot;

    // Ticket
    mapping(uint256 => bool) public ticketUsed;
    mapping(uint256 => bool) public jobChanged;

    // Modifier
    modifier withinMaxAmountPerAddress(uint256 amount, uint256 allowedAmount) {
        require(mintedAmount[msg.sender] + amount <= allowedAmount, 'Over Max Amount Per Address');
        _;
    }
    modifier validProof(uint256 allowedAmount, bytes32[] calldata merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, allowedAmount));
        require(MerkleProof.verifyCalldata(merkleProof, merkleRoot, node), "Invalid proof");
        _;
    }
    modifier isTokenOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Not Token Owner");
        _;
    }
    modifier notUsed (uint256 _tokenId) {
        require(ticketUsed[_tokenId] == false, "Already Used");
        _;
    }
    modifier notChanged (uint256 _jobChangeTokenId) {
        require(jobChanged[_jobChangeTokenId] == false, "Already Changed");
        _;
    }

    // Event
    event SuperJobChanged(address _sender, uint256 _tokenId, uint256 _jobChangeTokenId);

    // Constructor
    constructor() ERC721A("SuperJobChangeTicket2023Summer", "SJCT2023S") {
        grantRole(ADMIN, msg.sender);
    }

    // AirDrop
    function airdrop(address[] calldata addresses, uint256[] calldata amounts) external onlyRole(ADMIN) {
        require(addresses.length == amounts.length, 'Invalid Arguments');
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 amount = amounts[i];
            _safeMint(addresses[i], amount);
        }
    }

    // Mint
    function mint(uint256 _amount, uint256 _allowedAmount, bytes32[] calldata _merkleProof) external
        whenNotPaused
        withinMaxAmountPerAddress(_amount, _allowedAmount)
        validProof(_allowedAmount, _merkleProof)
    {
        mintedAmount[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    // Ticket
    function useTicket(uint256 _tokenId, uint256 _jobChangeTokenId) external
        whenNotPaused
        isTokenOwner(_tokenId)
        notUsed(_tokenId)
        notChanged(_jobChangeTokenId)
    {
        ticketUsed[_tokenId] = true;
        jobChanged[_jobChangeTokenId] = true;
        emit SuperJobChanged(msg.sender, _tokenId, _jobChangeTokenId);
    }

    // Getter
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (ticketUsed[_tokenId]) {
            return string(abi.encodePacked(ERC721A.tokenURI(_tokenId), usedSuffix, baseExtension));
        } else {
            return string(abi.encodePacked(ERC721A.tokenURI(_tokenId), baseExtension));
        }
    }
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    // Setter
    function setBaseURI(string memory _value) public onlyRole(ADMIN) {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) public onlyRole(ADMIN) {
        baseExtension = _value;
    }
    function resetBaseExtension() public onlyRole(ADMIN) {
        baseExtension = "";
    }
    function setMerkleRoot(bytes32 _value) public onlyRole(ADMIN) {
        merkleRoot = _value;
    }

    // Pausable
    function pause() public onlyRole(ADMIN) {
        _pause();
    }
    function unpause() public onlyRole(ADMIN) {
        _unpause();
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // OperatorFilterer
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) payable {
        require(!ticketUsed[tokenId], "This ticket is used");
        super.approve(operator, tokenId);
    }
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        require(!ticketUsed[tokenId], "This ticket is used");
        super.transferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        require(!ticketUsed[tokenId], "This ticket is used");
        super.safeTransferFrom(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) payable {
        require(!ticketUsed[tokenId], "This ticket is used");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Royalty
    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs) external override onlyRole(ADMIN) {
        _setTokenRoyalties(royaltyConfigs);
    }
    function setDefaultRoyalty(TokenRoyalty calldata royalty) external override onlyRole(ADMIN) {
        _setDefaultRoyalty(royalty);
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721AntiScam, EIP2981RoyaltyOverrideCore) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId) ||
            ERC721AntiScam.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}