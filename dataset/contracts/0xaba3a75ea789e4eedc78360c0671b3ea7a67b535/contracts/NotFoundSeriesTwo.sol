/* 
 _   _       _    ______                    _   _____           _             _____             
| \ | |     | |   |  ___|                  | | /  ___|         (_)           |_   _|            
|  \| | ___ | |_  | |_ ___  _   _ _ __   __| | \ `--.  ___ _ __ _  ___  ___    | |_      _____  
| . ` |/ _ \| __| |  _/ _ \| | | | '_ \ / _` |  `--. \/ _ \ '__| |/ _ \/ __|   | \ \ /\ / / _ \ 
| |\  | (_) | |_  | || (_) | |_| | | | | (_| | /\__/ /  __/ |  | |  __/\__ \   | |\ V  V / (_) |
\_| \_/\___/ \__| \_| \___/ \__,_|_| |_|\__,_| \____/ \___|_|  |_|\___||___/   \_/ \_/\_/ \___/ 
                                                                                                
   */                                                                                              
// SPDX-License-Identifier: MIT
// Built by --error
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

contract NotFoundSeriesTwo is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 1000;
    uint256 public cost = 0.0202 ether;
    uint256 public maxPerWallet = 2;
    uint256 public maxMintAmountPerTx = 2;
    string public baseURI;
    bool public paused = true;
    bool public allowListState = false;
    bool public waitListState = false;
    bool public publicMintOpen = false;
    bool public allowListMintOpen = false;
    bool public waitListMintOpen = false;
    mapping(address => bool) public allowList;
    mapping(address => bool) public waitList;
    
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721A(_tokenName, _tokenSymbol) {}

    modifier mintCompliance(uint256 quantity) {
        require(quantity > 0 && quantity <= maxMintAmountPerTx, "Invalid mint amount!");
        require(_numberMinted(msg.sender) + quantity <= maxPerWallet, "Max per wallet mint exceeded");
        require(totalSupply() + quantity < maxSupply + 1, "Max supply exceeded");
        _;
    }

    modifier mintPriceCompliance(uint256 quantity) {
        uint256 realCost = 0;
        require(msg.value >= cost * quantity - realCost, "Please send the exact amount.");
        _;
    }

    function editMintWindows(
        bool _publicMintOpen,
        bool _waitListMintOpen,
        bool _allowListMintOpen
    ) external onlyOwner {
        publicMintOpen = _publicMintOpen;
        allowListMintOpen = _allowListMintOpen;
        waitListMintOpen = _waitListMintOpen;
    }

    function allowListMint(uint256 quantity) public payable mintCompliance(quantity) mintPriceCompliance(quantity) {
        require(allowListMintOpen, "Allowlist is closed.");
        require(allowList[msg.sender], "Not on allowlist");
        require(msg.value >= 0.0202 ether, "Incorrect value");
        _safeMint(msg.sender, quantity);
    }

    function waitListMint(uint256 quantity) public payable mintCompliance(quantity) mintPriceCompliance(quantity) {
        require(waitListMintOpen, "Waitlist is closed.");
        require(waitList[msg.sender], "Not on waitlist");
        require(msg.value >= 0.0202 ether, "Incorrect value");
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) public payable mintCompliance(quantity) mintPriceCompliance(quantity) {
        require(publicMintOpen, "Public closed");
        require(msg.value >= 0.0202 ether, "Incorrect Value");
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity)
        public
        payable
        mintCompliance(quantity)
        onlyOwner
    {
        _safeMint(_msgSender(), quantity);
    }

    function mintBatch(address[] memory recipients) public onlyOwner {
    uint256 length = recipients.length;
    require(length > 0, "Empty recipient array");

    for (uint256 i = 0; i < length; i++) {
        _safeMint(recipients[i], 1);
    }
    }


    function reserveTokens(uint256 numTokens) external onlyOwner {
    require(totalSupply() + numTokens <= maxSupply, "Exceeds maximum supply");
    maxSupply -= numTokens;
    }

    function setWaitList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++){
            waitList[addresses[i]] = true;
        }
    }

    //Set Allowlist
    function setAllowList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++){
            allowList[addresses[i]] = true;
        }
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }


    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}