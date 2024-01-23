// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LMTwelveDaysXMas is ReentrancyGuard, Ownable, ERC1155Supply {

    uint256 public currentDayOfChristmas;

    mapping(uint256 => string) private _uris;

    mapping(address => uint256) public globalAllowList;

    mapping(uint256 => mapping(address => uint256)) public walletsMinted;

    bool public isPublicMintActive;

    address public lapinWallet; 

    constructor() payable ERC1155("https://orion.mypinata.cloud/ipfs/QmepxG3qD2qq9B9bCi83kQojbuzTCpnWUmnxys755qKzG3/{id}.json") {

        currentDayOfChristmas = 1;
        
        isPublicMintActive = false;
        
        lapinWallet = 0xd06124cf5F968f62fa0CF1e9399EEf967b367d3f; //Lapin's Wallet

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'Use your wallet to mint');
        _;
    }

    function setTokenUri(uint256 _tokenid, string memory newuri) external onlyOwner {
        _uris[_tokenid] = newuri;
    }

    function uri(uint256 _tokenid) override public view returns (string memory) {
        return(_uris[_tokenid]);
    }

    function mintedWallet(uint256 _tokenid, address walletAddress)public view returns(uint256)
    {
        return walletsMinted[_tokenid][walletAddress];
    }

    //Minting

    function mintDayOfChristmas() external nonReentrant callerIsUser {
        require(isPublicMintActive, 'minting not enabled');

        require(globalAllowList[msg.sender] > 0, 'Your Wallet Not found!');

        uint256 numberOfTokensMintedInCurrentDay = mintedWallet(currentDayOfChristmas, msg.sender);
        require(numberOfTokensMintedInCurrentDay < 1, 'You have already minted today!');

        walletsMinted[currentDayOfChristmas][msg.sender]= 1;

        _mint(msg.sender, currentDayOfChristmas, 1, "");
    }

    function mintDayOfChristmasForLapin(uint256 day_, uint256 quantity_) external onlyOwner {
        require(day_ > 0 || day_ < 13, "There is only 12 days of christmas!"); //Ricardo: Check and test this ASAP
        _mint(msg.sender, day_, quantity_, "");
    }

    //Change current day

    function changeCurrentDay(uint256 day_) external onlyOwner{
        currentDayOfChristmas = day_;
    }

    //Seed Allowlist

    function addToGlobalAllowList(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            globalAllowList[addresses[i]] = 1;
        }
    }

    //Toggle Public mint status

    function setIsPublicMintActive() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    string private customContractURI = "https://orion.mypinata.cloud/ipfs/QmRZvsyabHNwsguGVP69s24bf43cqTiNULiVyakBoLW38E/metadata.json";

    function setContractURI(string memory customContractURI_) external onlyOwner {
        customContractURI = customContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return customContractURI;
    }

    //Withdraw failsafe

    function withdraw() external onlyOwner {
        uint256 _totalWithdrawal = address(this).balance;
        address withdrawToLapinWallet = msg.sender;
        (bool successLapin, ) = withdrawToLapinWallet.call{ value: _totalWithdrawal }('');
        require(successLapin, 'withdraw failed');
    }

}