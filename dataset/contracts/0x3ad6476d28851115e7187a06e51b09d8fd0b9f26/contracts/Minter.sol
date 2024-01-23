// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Manifold {
    function mintBatch(address creatorContractAddress, uint256 claimIndex, uint16 mintCount, uint32[] calldata mintIndices, bytes32[][] calldata merkleProofs, address mintFor) external payable;
}

contract Minter is Ownable {
    address public kudasai = 0xECD0CBBdbFB07986E22981C8D78e17a952605854;
    address public manifoldContract = 0x44e94034AFcE2Dd3CD5Eb62528f239686Fc8f162;
    minterChaild private immutable _childContract;
    cloneFactory private immutable _cloneContract;
    mapping(address => uint256) public childCount;
    mapping(address => mapping(uint256 => address)) public child;

    constructor () {
        _childContract = new minterChaild(address(this));
        _cloneContract = new cloneFactory();
    }
    receive() external payable {}

    modifier onlyHolder() {
        require(IERC721(kudasai).balanceOf(msg.sender) >= 1, "Agenai");
        _;
    }

    modifier checkId(uint256 _startId, uint256 _endId) {
        require(_startId <= _endId && _startId <= childCount[msg.sender] && _endId <= childCount[msg.sender], "Invalid ID");
        _;
    }
    
    function createAddress(uint256 _quantity) public onlyHolder {
        for (uint256 i = 0; i < _quantity; i++) {
            child[msg.sender][childCount[msg.sender]] = cloneFactory(_cloneContract).createClone(address(_childContract));
            childCount[msg.sender]++;
        }
    }

    function sendETH(uint256 _startId, uint256 _endId) public payable onlyHolder checkId(_startId, _endId) {
        uint256 beforeBalance = address(this).balance;
        uint256 value = msg.value / (_endId - _startId + 1);
        for (uint256 i = _startId; i <= _endId; i++) {
            address(child[msg.sender][i]).call{value: value}("");
        }
        // refund
        if (beforeBalance < address(this).balance) {
            payable(msg.sender).transfer(address(this).balance - beforeBalance);
        }
    }

    function run(address _creatorContractAddress, uint256 _claimIndex, uint16 _mintCount, uint256 _cost, uint256 _startId, uint256 _endId) public onlyHolder checkId(_startId, _endId) {
        for (uint256 i = _startId; i <= _endId; i++) {
            minterChaild(payable(child[msg.sender][i])).run(_creatorContractAddress, _claimIndex, _mintCount, _cost, manifoldContract);
        }
    }

    function OwnerTest(address _creatorContractAddress, uint256 _claimIndex, uint16 _mintCount, uint256 _cost) public onlyOwner {
        uint32[] memory mintIndices;
        bytes32[][] memory merkleProofs;
        Manifold(manifoldContract).mintBatch{value: _cost * _mintCount}(_creatorContractAddress, _claimIndex, _mintCount, mintIndices, merkleProofs, address(this));
    }

    function withdrawETH(uint256 _startId, uint256 _endId) public checkId(_startId, _endId) {
        uint256 beforeBalance = address(this).balance;
        for (uint256 i = _startId; i <= _endId; i++) {
            minterChaild(payable(child[msg.sender][i])).withdrawETH();
        }
        payable(msg.sender).transfer(address(this).balance - beforeBalance);
    }

    function withdrawNFT721(uint256 _startId, uint256 _endId, address _contract, uint256[] calldata tokenId) public checkId(_startId, _endId) {
        uint256 idx;
        for (uint256 i = _startId; i <= _endId; i++) {
            minterChaild(payable(child[msg.sender][i])).withdrawNFT721(_contract, tokenId[idx], msg.sender);
            idx++;
        }
    }

    function withdrawNFT1155(uint256 _startId, uint256 _endId, address _contract, uint256 tokenId) public checkId(_startId, _endId) {
        uint256 idx;
        for (uint256 i = _startId; i <= _endId; i++) {
            minterChaild(payable(child[msg.sender][i])).withdrawNFT1155(_contract, tokenId, msg.sender);
            idx++;
        }
    }

    /**
     * @notice Only Owner
     */
    function recoverETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @notice Only Owner
     */
    function recoverERC20(address _contract) public onlyOwner {
        IERC20(_contract).transfer(msg.sender, IERC20(_contract).balanceOf(address(this)));
    }

    /**
     * @notice Only Owner
     */
    function recoverNFT721(address _contract, uint256 _tokenId) public onlyOwner {
        IERC721(_contract).safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    /**
     * @notice Only Owner
     */
    function recoverNFT1155(address _contract, uint256 _tokenId, uint256 _amount, bytes memory _data) public onlyOwner {
        IERC1155(_contract).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, _data);
    }

    
    /**
     * @notice Only Owner
     */
    function setContract(address _kudasai, address _manifold) public onlyOwner {
        kudasai = _kudasai;
        manifoldContract = _manifold;
    }
}

contract minterChaild is IERC721Receiver {
    address public immutable owner;
    constructor(address _newOwner) {
        owner = _newOwner;
    }
    receive() external payable {}

    modifier onlyOwner() {
        require(owner == msg.sender, "No Call");
        _;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) public virtual returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function withdrawNFT721(address _contract, uint256 _tokenId, address _to) public onlyOwner {
        IERC721(_contract).safeTransferFrom(address(this), _to, _tokenId);
    }

    function withdrawNFT1155(address _contract, uint256 _tokenId, address _to) public onlyOwner {
        bytes memory data;
        uint256 amount = IERC1155(_contract).balanceOf(address(this), _tokenId);
        if (amount != 0) {
            IERC1155(_contract).safeTransferFrom(address(this), _to, _tokenId, amount, data);
        }
    }

    function withdrawETH() public onlyOwner {
        address(owner).call{value: address(this).balance}("");
    }

    function run(address _creatorContractAddress, uint256 _claimIndex, uint16 _mintCount, uint256 _cost, address _callContract) public onlyOwner {
        uint32[] memory mintIndices;
        bytes32[][] memory merkleProofs;
        Manifold(_callContract).mintBatch{value: _cost * _mintCount}(_creatorContractAddress, _claimIndex, _mintCount, mintIndices, merkleProofs, address(this));
    }
}

contract cloneFactory {
    function createClone(address logicContractAddress) external returns(address result){
        
        bytes20 addressBytes = bytes20(logicContractAddress);
        assembly{
            let clone:= mload(0x40) // Jump to the end of the currently allocated memory- 0x40 is the free memory pointer. It allows us to add own code
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000) // store 32 bytes (0x3d602...) to memory starting at the position clone
            mstore(add(clone, 0x14), addressBytes) // add the address at the location clone + 20 bytes. 0x14 is hexadecimal and is 20 in decimal
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000) // add the rest of the code at position 40 bytes (0x28 = 40)
            result := create(0, clone, 0x37)
        }
    }
}