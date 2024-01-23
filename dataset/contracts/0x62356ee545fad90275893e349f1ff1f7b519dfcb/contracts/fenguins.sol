// SPDX-License-Identifier: MIT

/***
 *                                                                               
 *         _|_|                                          _|                      
 *       _|        _|_|    _|_|_|      _|_|_|  _|    _|      _|_|_|      _|_|_|  
 *     _|_|_|_|  _|_|_|_|  _|    _|  _|    _|  _|    _|  _|  _|    _|  _|_|      
 *       _|      _|        _|    _|  _|    _|  _|    _|  _|  _|    _|      _|_|  
 *       _|        _|_|_|  _|    _|    _|_|_|    _|_|_|  _|  _|    _|  _|_|_|    
 *       sculpted by mr.feng >.<           _|                                    
 *       contract by mrs.feng >.<        _|_|                                      
 */

pragma solidity 0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract fenguins is ERC721A, DefaultOperatorFilterer, Ownable {

    string public baseURI = "ipfs://bafybeifx6bep6ujsh54u62vofqu5ga5vwzlgaonfxc5x323nn4uzssaem4/";
    uint256 public price = 0.0049 ether;
    uint256 public maxSupply = 4444;
    uint256 public maxPerTransaction = 3;
    uint256 private maxPerWallet = 3;
    bool public saleActive;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "go back to your wallet feng >.<");
        _;
    }
    constructor () ERC721A("thefenguins", "fengs") {
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function startSale() external onlyOwner {
        require(saleActive == false);
        saleActive = true;
    }

    function stopSale() external onlyOwner {
        require(saleActive == true);
        saleActive = false;
    }

    function publicMint(uint256 amount) public payable callerIsUser{
        require(saleActive);
        require(amount <= maxPerTransaction, "oopsie! check wallet count feng >.<");
        require(totalSupply() + amount <= maxSupply, "too late feng >.<");
        require(_numberMinted(msg.sender) + amount <= maxPerWallet, "get that burner wallet out feng >.<");
        require(msg.value >= price * amount, "uh! hate to say but you need to enter the correct amount feng >.<");
        if (msg.value >= price * amount) {
            _safeMint(msg.sender, amount);
        }
    }    

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function reduceSupply(uint256 newMaxSupply) public onlyOwner {
    require(newMaxSupply < maxSupply, "can't exceed the supply remember mr.feng? love, mrs.feng >.<?");
    maxSupply = newMaxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
        
	}

    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    } 

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply);
        _safeMint(msg.sender, quantity);
    }

    function treasuryMint(uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= maxSupply);
        require(quantity > 0, "Invalid mint amount");
        require(
            totalSupply() + quantity <= maxSupply,
            "Maximum supply exceeded"
        );
        _safeMint(msg.sender, quantity);
    }    

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
}