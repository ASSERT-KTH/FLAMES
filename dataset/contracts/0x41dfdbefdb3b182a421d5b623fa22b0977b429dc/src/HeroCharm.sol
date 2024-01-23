// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "ERC721A/extensions/ERC721AQueryable.sol";

import "operator-filter-registry/OperatorFilterer.sol";

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";

contract HeroCharm is Ownable, Pausable, ReentrancyGuard, ERC721AQueryable, OperatorFilterer {
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                               ADDRESSES
    //////////////////////////////////////////////////////////////*/

    IERC721 public tdc;

    /*//////////////////////////////////////////////////////////////
                            STANDARD STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The base URI for all tokens.
    string private _baseTokenURI;

    /// @notice Filter Address for marketplaces.
    mapping(address => bool) public filteredAddress;

    /// @notice Maximum number of mintable heroCharm.
    uint256 public maxSupply = 666;

    /*//////////////////////////////////////////////////////////////
                              STAKE STATE
    //////////////////////////////////////////////////////////////*/
    address public signer;

    uint256 public totalStake;

    mapping(uint256 => stakeSlot) public stakeSlots;
    mapping(uint256 => uint32[]) public stakeTokens;

    struct stakeSlot {
        uint32 stakeType;
        uint64 stakeTime;
        uint64 nextMintTime;
        address owner;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA wallets can mint");
        _;
    }

    constructor(address _tdc)
        ERC721A("HeroCharm", "HC")
        OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true)
    {
        filteredAddress[0x00000000000111AbE46ff893f3B2fdF1F759a8A8] = true;
        filteredAddress[0xF849de01B080aDC3A814FaBE1E2087475cF2E354] = true;
        filteredAddress[0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e] = true;

        tdc = IERC721(_tdc);
    }

    function stake(uint256 _stakeType, uint32[] calldata _tokenIds, bytes[] calldata _signs)
        external
        onlyEOA
        nonReentrant
    {
        require(_tokenIds.length > 0 && _tokenIds.length <= 3, "Invalid tokenIds");
        require(_tokenIds.length == _signs.length, "Invalid signature data");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(tdc.ownerOf(_tokenIds[i]) == msg.sender, "Invalid token owner");
            require(verify(keccak256(abi.encodePacked(_stakeType, _tokenIds[i])), _signs[i]), "Invalid signature");
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tdc.transferFrom(msg.sender, address(this), _tokenIds[i]);
        }

        uint256 nextMintTime = block.timestamp + 2 weeks;
        if (_stakeType == 3) {
            nextMintTime = block.timestamp + 10 days;
        }

        stakeTokens[totalStake] = _tokenIds;
        stakeSlots[totalStake] = stakeSlot({
            stakeType: uint32(_stakeType),
            stakeTime: uint64(block.timestamp),
            nextMintTime: uint64(nextMintTime),
            owner: msg.sender
        });

        totalStake += 1;
    }

    function unstake(uint256 _slot) external nonReentrant {
        require(stakeSlots[_slot].owner == msg.sender, "Invalid slot owner");

        for (uint256 i = 0; i < stakeTokens[_slot].length; i++) {
            tdc.transferFrom(address(this), msg.sender, stakeTokens[_slot][i]);
        }
        delete stakeTokens[_slot];
        delete stakeSlots[_slot];
    }

    function mint(uint256 _slotId) external payable onlyEOA nonReentrant {
        stakeSlot memory _stakeSlot = stakeSlots[_slotId];
        require(_stakeSlot.owner == msg.sender, "Not owner");

        uint256 totalMint = _calculateMintNum(_stakeSlot);
        if (totalMint == 0) {
            revert("Not available to mint");
        }

        require(_totalMinted() + totalMint <= maxSupply, "Max supply reached");

        uint256 nextMintTime = _stakeSlot.stakeTime + 2 weeks;
        if (_stakeSlot.stakeType == 3) {
            nextMintTime = _stakeSlot.stakeTime + 10 days;
        }

        stakeSlots[_slotId] = stakeSlot({
            stakeType: _stakeSlot.stakeType,
            stakeTime: _stakeSlot.stakeTime,
            nextMintTime: uint64(nextMintTime),
            owner: _stakeSlot.owner
        });

        _mint(_stakeSlot.owner, totalMint);
    }

    function _calculateMintNum(stakeSlot memory _stakeSlot) internal view returns (uint256 num) {
        uint256 _stakeTime = block.timestamp - _stakeSlot.stakeTime;

        if (_stakeSlot.stakeType == 0) {
            num = 1;
        } else if (_stakeSlot.stakeType == 1) {
            num = 2;
        } else if (_stakeSlot.stakeType == 2 || _stakeSlot.stakeType == 3) {
            num = 3;
        } else {
            revert("Invalid stake type");
        }

        if (_stakeSlot.stakeType == 3) {
            if (_stakeTime / 10 days >= 1) {
                return num;
            }
        } else {
            if (_stakeTime / 2 weeks >= 1) {
                return num;
            }
        }
        return 0;
    }

    function verify(bytes32 _hash, bytes memory _signature) internal view returns (bool) {
        return _hash.toEthSignedMessageHash().recover(_signature) == signer;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setFilteredAddress(address _address, bool _isFiltered) external onlyOwner {
        filteredAddress[_address] = _isFiltered;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /* ============ ERC721A ============ */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public payable override (ERC721A, IERC721A) {
        require(!filteredAddress[to], "Not allowed to approve to this address");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override (ERC721A, IERC721A) {
        require(!filteredAddress[operator], "Not allowed to approval this address");
        super.setApprovalForAll(operator, approved);
    }

    /* ============ External Getter Functions ============ */

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721A, IERC721A) returns (bool) {
        return ERC721A.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getStakeSlotByAddress(address _address)
        external
        view
        returns (uint256[] memory, stakeSlot[] memory, uint32[][] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < totalStake; i++) {
            if (stakeSlots[i].owner == _address) {
                count++;
            }
        }

        uint256[] memory _slotIds = new uint256[](count);
        stakeSlot[] memory _stakeSlots = new stakeSlot[](count);
        uint32[][] memory _stakeTokens = new uint32[][](count);
        uint256 index;
        for (uint256 i = 0; i < totalStake; i++) {
            if (stakeSlots[i].owner == _address) {
                _stakeSlots[index] = stakeSlots[i];
                _stakeTokens[index] = stakeTokens[i];
                _slotIds[index] = i;
                index++;
            }
        }

        return (_slotIds, _stakeSlots, _stakeTokens);
    }

    function calculateMintNum(uint256 _slotId) external view returns (uint256) {
        return _calculateMintNum(stakeSlots[_slotId]);
    }
}
