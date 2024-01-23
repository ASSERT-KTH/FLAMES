//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";


contract PixelYurei is ERC721Burnable, ERC2981, Ownable, ReentrancyGuard {

    error SaleClosed();

    uint256 private _supply;
    using Strings for uint256;

    //var
    uint256 public maxSupply = 1111;
    uint256 MaxPerMint = 1;
    uint256 public price = 0 ether;
    string public URI;
    string private uriSuffix = ".json";
    mapping(address => uint256) public CanMint;
    mapping(uint256 => bool) public isBurned; 
    mapping(address => uint256) private _alreadyMinted;

    enum State {
    Closed,
    Private,
    Public
    }

    State public salestatus = State.Closed;

    IERC721 public Yurei;
    //only approved operators
    mapping (address => bool) public ApprovedAddr; 

    constructor(address _RoyaltyReceiver, uint96 _royaltyAmount,address _contr, string memory _uri)  ERC721("Pixel Yurei", "0xYurei")  {
        setRoyaltyInfo(_RoyaltyReceiver,_royaltyAmount);
        Yurei = IERC721(_contr);
        URI=_uri;
    }

   
    modifier IsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }
    
    modifier OnlyWhitelistedOp(address _ops){
        require(ApprovedAddr[_ops] == true, "Not approved operator");
        _;
    }

    function setState(State _saleState) external onlyOwner {
    
    salestatus = _saleState;
    
    }

    function totalSupply() public view returns (uint256) {
        return _supply;
  }

    //Metadata

    function _baseURI() internal view virtual override returns (string memory) {
        return URI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(URI, Strings.toString(tokenId), uriSuffix));
    }


    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        URI = _newBaseURI;
    }

  
    //Mint

    function mint(uint256 amount) public payable {
        uint256 YureiHeld;
        require((totalSupply() + amount) <= maxSupply, "max supply reached");

        if (salestatus == State.Private){
            require((YureiHeld = Yurei.balanceOf(msg.sender)) >= 1, "max supply reached");
            require(YureiHeld < _alreadyMinted[msg.sender],"Insufficient mints left");
            for (uint256 i = 0; i < YureiHeld; i++) {
            _supply++;
            _mint(msg.sender, totalSupply());
            
            }
            _alreadyMinted[msg.sender] += YureiHeld;
        }
        else if (salestatus == State.Public){
            require(amount <= MaxPerMint - _alreadyMinted[msg.sender],"Insufficient mints left");
            _alreadyMinted[msg.sender] += amount;
            _supply++;
            _mint(msg.sender, totalSupply());
        }

        else revert SaleClosed();

    }

    //owner mint
    function OwnerMint(address to, uint256 amount) public onlyOwner {
        for (uint256 i = 1; i <= amount; i++) {
            _supply++;
            _mint(to, totalSupply());

        }
    }

    //approval modification

    function AddApprover(address[] calldata Approver, bool[] calldata permission) public onlyOwner {
        for(uint256 i = 0;i< Approver.length;i++){
            ApprovedAddr[Approver[i]] = permission[i];
        }
    }

   /* function _ApplyApprover() internal {
        for(uint256 i = 0;i< OperatorList.length;i++){
            ApprovedAddr[OperatorList[i]] = true;
        }
    }*/


    //Approval Override functions

    function setApprovalForAll(address operator, bool approved) public virtual OnlyWhitelistedOp(operator) override(ERC721) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public OnlyWhitelistedOp(operator) override {
        super.approve(operator, tokenId);
  }

    function transferFrom(address from, address to, uint256 tokenId) public  override OnlyWhitelistedOp(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public  OnlyWhitelistedOp(from) override  {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public  OnlyWhitelistedOp(from) override  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

    //royalty 100 is 1%
    
     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
         return super.supportsInterface(interfaceId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyAmount) public onlyOwner {
        _setDefaultRoyalty(_receiver,_royaltyAmount);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
