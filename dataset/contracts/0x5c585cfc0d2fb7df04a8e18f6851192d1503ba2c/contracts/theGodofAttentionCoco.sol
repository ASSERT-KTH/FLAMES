// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "erc721a/contracts/ERC721A.sol";

contract GodOFAttention is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;
    // elder = OG, BAPTIZED = WL , BELIEVER = public
    enum SaleStatus {
        PAUSED,
        ELDER,
        BAPTIZED,
        BELIEVER
    }
    // set default Pause
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    bool public revealed = false; 
    string private baseTokenURI;
    string public notRevealedURI;

    bytes32[3] public merkleRoot;
    address private teamWallet; 

    address public royaltyAddress; // Only in unsupported marketplaces, we need to go directly to setup
    uint96 public royaltyFeesInBips;
     
    //1 ether == 1000000000000000000
    uint256 public allowListPrice = 0 ether; //elder and baptized
    uint256 public believerPrice = 0.0088 ether; //believer
    uint256 private constant _TotalCollectionSize = 8888; 
    uint256 public MAX_PER_Transaction = 2; 
    uint256 public MAX_PER_Address_FOR_ALLOW_LIST = 2; 

    // set each spots 
    uint256 private teamNFTsTaked;
    uint16 private teamLimit = 700; 
    
    uint256 private soldElder;
    uint256 private elderSpots = 1600;  

    uint256 private soldBaptized;
    uint256 private BaptizedSpots = 4500; 
     
    constructor( string memory _hiddenURI, uint96 _royaltyFeesInBips, address _teamWallet) ERC721A("God Of Attenton Coco","GOA")
    {
        //setBaseURI(_uri); //We just run it when we reveal it.
        setNotRevealedURI(_hiddenURI);
        royaltyFeesInBips = _royaltyFeesInBips;
        //setMerkleRoot(0,Elder,Whitelist);//Register when the list is finalized.
        teamWallet = _teamWallet;
        setRoyaltyInfo(teamWallet,_royaltyFeesInBips);   
        reserveNFT(5); 
    }
    
    
    modifier checkMintCount(uint256 _quantity,uint256 _price){
        require(totalSupply().add(_quantity) <= _TotalCollectionSize, "reached max supply");
        require(_quantity <= MAX_PER_Transaction, "Max per transaction exceeded");
        require(msg.value >= _price.mul(_quantity), "Need to send more ETH.");  
         _;
    }

    // sale function 
     function reserveNFT(uint256 quantity) public onlyOwner {
        require(totalSupply().add(quantity) <= _TotalCollectionSize, "reached max supply");
        require(teamNFTsTaked.add(quantity) <= teamLimit, "Reserve limit exceeded.");
        teamNFTsTaked = teamNFTsTaked.add(quantity);
        _safeMint(teamWallet, quantity);
    }

    // wl and og sale 
    function whoMetCocoMint(uint256 quantity, bytes32[] calldata merkleproof) public payable checkMintCount(quantity,allowListPrice){     
         require(saleStatus == SaleStatus.ELDER || saleStatus == SaleStatus.BAPTIZED, "not start ELDER or BAPTIZED mint");
         require(isValid(merkleproof, keccak256(abi.encodePacked(msg.sender))), "No permission(Not BAPTIZED or ELDER)");
         require((_numberMinted(msg.sender).add(quantity) <= MAX_PER_Address_FOR_ALLOW_LIST),"Quantity exceeds allowed Mints"); // 수정하는 포인트 

        if(saleStatus == SaleStatus.BAPTIZED) {
            require(soldBaptized.add(quantity) <= BaptizedSpots,"Baptized sold out");
            soldBaptized = soldBaptized.add(quantity);
        } else {
            require(soldElder.add(quantity) <= elderSpots,"ELDER sold out");
            soldElder = soldElder.add(quantity);
        }
        _safeMint(msg.sender, quantity);
    }

    // public sale 
    function whoWillMeetCocoMint(uint256 quantity) public payable checkMintCount(quantity,believerPrice) {
        require(saleStatus == SaleStatus.BELIEVER, "BELIEVER minting not start");
        _safeMint(msg.sender, quantity);
    }


    function supportsInterface(bytes4 interfaceId)   public view override(ERC721A) returns (bool){
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }
        
    function isValid(bytes32[] memory merkleproof,bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(merkleproof, merkleRoot[uint(saleStatus)], leaf);
    }


    //get function
    function getSaleStatus() public view returns (SaleStatus){
        return saleStatus;
    }

    function getPrice(uint256 _count) public view returns(uint256){  
        if(saleStatus == SaleStatus.BELIEVER)
         return believerPrice.mul(_count);
        else
         return allowListPrice.mul(_count);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory){
        return _ownershipOf(tokenId);
    }

     function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function getNumberMinted(address _address) public view returns (uint256) { 
        return _numberMinted(_address);
    }
  
    function getSoldNum() public view returns (uint256) { 
       if(saleStatus == SaleStatus.ELDER)
         return soldElder;
       else if(saleStatus == SaleStatus.BAPTIZED)
         return soldBaptized;
       else 
        return 0;
    }


    function getSpots() public view returns (uint256) { 
       if(saleStatus == SaleStatus.ELDER)
         return elderSpots;
       else if(saleStatus == SaleStatus.BAPTIZED)
         return BaptizedSpots;
       else if(saleStatus == SaleStatus.BELIEVER)
         return _TotalCollectionSize;
       else 
        return 0;
    }

    function royaltyInfo(uint256 _salePrice) external view virtual returns (address, uint256){
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice) view public returns (uint256) {
        return (_salePrice.div(10000)).mul(royaltyFeesInBips);
    }


    //set function
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setNotRevealedURI(string memory URI) public onlyOwner {
        notRevealedURI = URI;
    }

    function setPublicPrice(uint256 _newPrice) public onlyOwner {  
        believerPrice = _newPrice;
    }

    function setAccessListPrice(uint256 _newPrice) public onlyOwner {  
        allowListPrice = _newPrice;
    }

    function setMerkleRoot(bytes32 _ElderRoot,bytes32 _baptizedRoot) public onlyOwner {
        merkleRoot[0] = 0;
        merkleRoot[1] = _ElderRoot;
        merkleRoot[2] = _baptizedRoot;
    } 

    function setElderLimit(uint256 _newLimit) public onlyOwner {
        elderSpots = _newLimit;
    }

    function setBaptizedLimit(uint256 _newLimit) public onlyOwner {
        BaptizedSpots = _newLimit;
    }

    function setMAX_PER_Transaction(uint256 _newLimit) public onlyOwner {
        MAX_PER_Transaction = _newLimit;
    }

    function setMAX_PER_Address_FOR_ALLOW_LIST(uint256 _newLimit) public onlyOwner {
        MAX_PER_Address_FOR_ALLOW_LIST = _newLimit;
    }

    function setTeamWallet(address _newTeamWallet) public onlyOwner {
        teamWallet = _newTeamWallet;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function setSaleStatus(SaleStatus _status) public onlyOwner {
        saleStatus = _status;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
           if (revealed) {
             string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0 ? string( abi.encodePacked(baseURI, tokenId.toString()) ) : "";
        } else {
            return notRevealedURI;
        }
    }
    
    function reveal(string memory _uri) public onlyOwner {
        if(!revealed){
            setBaseURI(_uri);
        }
        revealed = !revealed;
    } 

    function withdraw() public onlyOwner nonReentrant { 
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function airdrop(address beneficiary, uint256 amount) public onlyOwner {
        require(beneficiary != address(0), "Cannot airdrop to zero address");
        require(totalSupply().add(amount) <= _TotalCollectionSize, "reached max supply");
        _safeMint(beneficiary, amount);
    }
}