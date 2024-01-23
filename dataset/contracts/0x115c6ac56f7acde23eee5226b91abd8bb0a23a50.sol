// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title ERC721SS (ERC721 Sumo Soul) Minter Public
 * @author 0xSumo
 */

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

interface IERC721SS {
    function mint(uint256 tokenId_, address to_) external;
    function ownerOf(uint256 tokenId_) external view returns (address);
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "onlyOwner not owner!");_; } 
    function transferOwnership(address new_) external onlyOwner { address _old = owner; owner = new_; emit OwnershipTransferred(_old, new_); }
}

contract ERC721SSMinter is Ownable {

    IERC721SS public ERC721SS = IERC721SS(0x508c1CC6099F273A751386561e49Cf279571E716);
    IERC721 public ERC721 = IERC721(0xd2b14f166Daeb1Ec73a4901745DBE2199Db6B40C);
    uint256 public Ids = 610;
    uint256 public constant optionPrice = 0.01 ether;
    mapping(uint256 => string) public ADD;
    struct IdAndAdd { uint256 ids_; string add_; }

    function claimSBT(uint256 tokenId, string memory add) external payable {
            require(ERC721.ownerOf(tokenId) == msg.sender, "Not owner");
            require(msg.value == optionPrice, "Value sent is not correct");
            require(bytes(add).length > 0, "Give addy");
            ADD[tokenId] = add;
            ERC721SS.mint(tokenId, msg.sender);
    }

    function claimSBTFree(uint256 tokenId) external {
        require(ERC721.ownerOf(tokenId) == msg.sender, "Not owner");
        ERC721SS.mint(tokenId, msg.sender);
    }

    function mintSBT(string memory add) external payable {
        require(msg.value == optionPrice, "Value sent is not correct");
        require(bytes(add).length > 0, "Give addy");
        require(Ids < 999, "No more");

        ADD[Ids] = add;
        ERC721SS.mint(Ids, msg.sender);
        Ids++;
    }

    function mintSBTFree() external {
        require(Ids < 999, "No more");
        ERC721SS.mint(Ids, msg.sender);
        Ids++;
    }

    function getAllIdAndAdd(uint256 _startIndex, uint256 _count) external view returns (IdAndAdd[] memory) {
        IdAndAdd[] memory _IdAndAdd = new IdAndAdd[](_count);
        for (uint256 i = 0; i < _count; i++) {
            uint256 currentIndex = _startIndex + i;
            uint256 _ids = currentIndex;
            string memory _add  = ADD[currentIndex];
            _IdAndAdd[i] = IdAndAdd(_ids, _add);
        }
        return _IdAndAdd;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}