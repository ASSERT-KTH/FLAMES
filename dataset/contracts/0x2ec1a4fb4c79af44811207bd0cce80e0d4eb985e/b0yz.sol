// SPDX-License-Identifier: MIT

// -------- b0yz! --------
// https://twitter.com/b0yzb0yz

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "./IB0yzDescriptor.sol";
import "./vrf.sol";

pragma solidity ^0.8.7;

contract b0yz is Ownable, ERC721A, ReentrancyGuard, VRFv2DirectFundingConsumer {
    constructor(IB0yzDescriptor _descriptor) ERC721A("b0yz", "B0YZ") {
        descriptor = _descriptor;
        conf.maxSupply = 10000;
        conf.maxMint = 20;
        conf.pause = true;
    }

    struct B0yzConf {
        uint256 maxSupply;
        uint256 maxMint;
        bool pause;
    }

    IB0yzDescriptor public descriptor;
    B0yzConf public conf;
    mapping(uint256 => uint256) public seeds;
    uint256 lastId = 1;

    /* MINT FUNCTION */
    function getB0yz(uint256 quantity) external payable {
        require(!conf.pause, "Paused.");
        require(
            numberMinted(msg.sender) + quantity <= conf.maxMint,
            "Exceed maxmium."
        );
        require(totalSupply() + quantity <= conf.maxSupply, "All minted.");

        _getB0yz(quantity);
    }

    /* MINT PRIVATE FUNCTION */
    function _getB0yz(uint256 quantity) private {
        for (uint256 i = 0; i < quantity; i++) {
            seeds[lastId] = getSeed(lastId);
            lastId += 1;
        }

        _safeMint(msg.sender, quantity);
    }

    /* RESERVE BY OWNER */
    function reserve(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= conf.maxSupply, "All minted.");
        _getB0yz(quantity);
    }

    /* RELEASE ALL CONTRACT ETH */
    function release() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, ".");
    }

    /* RELEASE ALL CONTRACT CHAINLINK */
    function releaseLink() external onlyOwner {
        _withdrawLink();
    }

    /* GET RANDOM SEED */
    function getSeed(uint256 tokenId) private view returns (uint256) {
        uint256 randomlize = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    tokenId,
                    msg.sender
                )
            )
        );
        return randomlize;
    }

    /* SET DESCRIPTOR */
    function updateDescriptor(IB0yzDescriptor _descriptor) external onlyOwner {
        descriptor = _descriptor;
    }

    /* SET PAUSE STATUS */
    function updatePause(bool _pause) external onlyOwner {
        conf.pause = _pause;
    }

    /* REQUEST HASH FROM CHAINLINK VRF */
    function requestHash() external onlyOwner {
        require(!requested, "Requested.");
        _requestRandomWords();
    }

    /* OVERRIDE TOKENURI */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId <= lastId, "Invalid token.");
        require(hash.length > 0, "No hash.");
        uint256 seed = seeds[tokenId];
        return descriptor.tokenURI(tokenId, seed, hash);
    }

    /* OVERRIDE STARTTOKENID */
    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    /* GET NUMBERMINTED */
    function numberMinted(address _addr) public view returns (uint256) {
        return _numberMinted(_addr);
    }

    /* GET TOKENSOFOWNER */
    function tokensOfOwner(address owner)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}
