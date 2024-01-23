// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NotYourAmigos is
    ERC721,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    address proxyRegistryAddress;

    uint256 public maxSupply = 6969;

    string public baseURI;
    string public baseExtension = ".json";

    bool public publicM = true;

    uint256 _price = 1000000000000000; // 0.001 ETH

    Counters.Counter private _tokenIds;

    mapping(address => uint256) private _freeTokenCount;
    mapping(address => uint256) private _paidTokenCount;

    uint256[] private _teamShares = [100];
    address[] private _team = [
        0x9911bA9D7f479C52724C9493EF1f0ff6b4b2b702 // Deployer Account gets 100% of the total revenue
    ];

    constructor(string memory uri, address _proxyRegistryAddress)
        ERC721("NotYourAmigos", "NYA")
        PaymentSplitter(_team, _teamShares)
        ReentrancyGuard()
    {
        proxyRegistryAddress = _proxyRegistryAddress;
        setBaseURI(uri);
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }

    function publicSaleMint(uint256 _amount) external payable onlyAccounts {
        require(publicM, "NotYourAmigos: Public Mint is OFF");
        require(_amount > 0, "NotYourAmigos: zero amount");

        uint current = _tokenIds.current();

        require(current + _amount <= maxSupply, "NotYourAmigos: Max supply exceeded");
        require(_freeTokenCount[msg.sender] + _paidTokenCount[msg.sender] < 10, "NotYourAmigos: Max number of tokens exceeded");

        uint256 paidTokenCount = _paidTokenCount[msg.sender];
        uint256 freeTokenCount = _freeTokenCount[msg.sender];

        if (freeTokenCount < 3) {
            uint256 freeTokenLimit = 3 - freeTokenCount;
            uint256 freeTokenAmount = _amount;
            if (_amount > freeTokenLimit) {
                freeTokenAmount = freeTokenLimit;
            }

            for (uint256 i = 0; i < freeTokenAmount; i++) {
                _freeTokenCount[msg.sender]++;
                mintInternal();
            }

            _amount -= freeTokenAmount;
        }

        if (_amount > 0) {
            uint256 paidTokenLimit = 7 - paidTokenCount;
            uint256 paidTokenAmount = _amount;
            if (_amount > paidTokenLimit) {
                paidTokenAmount = paidTokenLimit;
            }

            uint256 totalPrice = _price * paidTokenAmount;

            require(msg.value >= totalPrice, "NotYourAmigos: Insufficient Ether sent");

            for (uint256 i = 0; i < paidTokenAmount; i++) {
                _paidTokenCount[msg.sender]++;
                mintInternal();
            }

            if (msg.value > totalPrice) {
                payable(msg.sender).transfer(msg.value - totalPrice);
            }
        }
    }

    function reserve(address _to) external onlyOwner {
        uint256 current = _tokenIds.current();
        require(
            current + 50 <= maxSupply,
            "NotYourAmigos: Max supply exceeded"
        );
        for (uint i = 0; i < 50; i++) {
            _freeTokenCount[_to]++;
            mintInternal();
        }
    }


    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}



/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}