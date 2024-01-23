// SPDX-License-Identifier: MIT

//Developer : FazelPejmanfar , Twitter :@Pejmanfarfazel



pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Punkz is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer   {


  string public baseURI;
  string public notRevealedUri = "ipfs://bafkreichxls6ectuwjvskagniee7hs77usmrxaxknvdgcuuz76wnkgybnm";
  uint256 public cost = 0.003 ether;
  uint256 public maxSupply = 5787;
  uint256 public MaxperWallet = 30;
  bool public paused = false;
  bool public revealed = false;

  constructor() ERC721A("Punkz", "PNK") {}

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  // public
  /// @dev Public mint 
  function mint(uint256 tokens) public payable nonReentrant {
    require(!paused, "PNK: oops contract is paused");
    require(tokens <= MaxperWallet, "PNK: max mint amount per tx exceeded");
    require(totalSupply() + tokens <= maxSupply, "PNK: We Soldout");
    require(numberMinted(_msgSenderERC721A()) + tokens <= MaxperWallet, "PNK: Max NFT Per Wallet exceeded");

    if(numberMinted(_msgSenderERC721A()) == 0) {
    require(msg.value >= cost * (tokens - 1), "PNK: insufficient funds");
    } else {
        require(msg.value >= cost * tokens, "PNK: insufficient funds");
    }

      _safeMint(_msgSenderERC721A(), tokens);
    
  }

  /// @dev use it for giveaway and team mint
     function airdrop(uint256 _mintAmount, address destination) public onlyOwner nonReentrant {
    require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");

      _safeMint(destination, _mintAmount);
  }

/// @notice returns metadata link of tokenid
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721AMetadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), ".json"))
        : "";
  }

     /// @notice return the number minted by an address
    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

    /// @notice return the tokens owned by an address
      function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
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

  //only owner
  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }

  /// @dev change the public max per wallet
  function setMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWallet = _limit;
  
  }
   /// @dev change the public price(amount need to be in wei)
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  /// @dev cut the supply if we dont sold out
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

 /// @dev set your baseuri
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

   /// @dev set hidden uri
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

 /// @dev to pause and unpause your contract(use booleans true or false)
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  
  /// @dev withdraw funds from contract
  function withdraw() public payable onlyOwner nonReentrant {
      uint256 balance = address(this).balance * 20 / 100;
      uint256 fullbalance = address(this).balance;
      payable(_msgSenderERC721A()).transfer(balance);
      payable(0x33D106e856ea174F0d6964470C68Fcc43Ee5E3E3).transfer(fullbalance);
  }


  /// Opensea Royalties

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }  
}
