// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {IBrawlerBearzDynamicItems} from "./interfaces/IBrawlerBearzDynamicItems.sol";
import "./tunnel/FxBaseRootTunnel.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**
 * @title BrawlerBearzBattlePass
 * @author @ScottMitchell18
 * @dev Battle pass public mint and L2 sync on mint, non-transferable, or sellable
 */
contract BrawlerBearzBattlePass is
    FxBaseRootTunnel,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable
{
    using Strings for uint256;

    /// @dev Sync actions
    bytes32 public constant MINTED = keccak256("MINTED");
    bytes32 public constant REWARDS_CLAIM = keccak256("REWARDS_CLAIM");

    /// @notice Vendor contract
    IBrawlerBearzDynamicItems public vendorContract;

    // @dev Base uri for the nft
    string private baseURI =
        "ipfs://bafybeigbadgbqqmajhdiqgh354pqqaf32daqlcddrf4xccvbo4vo6e2zfm/";

    // @dev The whitelist merkle root
    bytes32 public merkleRoot;

    /// @notice Free battle pass tier
    uint256 constant FREE_PASS = 1;

    /// @notice Pro battle pass tier
    uint256 constant PRO_PASS = 2;

    /// @notice Pro+ battle pass tier
    uint256 constant PRO_PLUS_PASS = 3;

    /// @notice Pro pass mint price
    uint256 public proPrice = 0.01 ether;

    /// @notice Pro plus pass mint price
    uint256 public proPlusPrice = 0.045 ether;

    // @dev Treasury
    address public treasury =
        payable(0x39bfA2b4319581bc885A2d4b9F0C90C2e1c24B87);

    /*
     * @notice All mints live ~ December 5th, 12PM EST
     * @dev Mints go live date
     */
    uint256 public liveAt = 1670259600;

    /*
     * @notice All mints expired ~ December 12th, 12PM EST
     * @dev Mints expire at
     */
    uint256 public expiresAt = 1670864400;

    /// @dev An address mapping for free pass minted
    mapping(address => bool) public addressToFreePassMinted;

    /// @dev A token mapping to battle pass type
    mapping(uint256 => uint256) public passes;

    /// @dev Thrown on approval
    error CannotApproveAll();

    /// @dev Thrown on transfer
    error Nontransferable();

    modifier whitelisted(bytes32[] calldata _proof) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof.");
        _;
    }

    modifier mintIsActive() {
        require(
            block.timestamp > liveAt && block.timestamp < expiresAt,
            "Minting is not active."
        );
        _;
    }

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _vendorContractAddress
    )
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
        ERC721A("Brawler Bearz Battle Pass", "BBBP")
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /**
     * @notice Free battle pass mint
     * @param _proof The bytes32 array proof to verify the merkle root
     */
    function freePassMint(bytes32[] calldata _proof)
        external
        mintIsActive
        whitelisted(_proof)
    {
        require(!addressToFreePassMinted[_msgSender()], "Already free minted");
        addressToFreePassMinted[_msgSender()] = true;
        _mintSync(_msgSender(), FREE_PASS);
    }

    /// @notice Pro pass mint
    function proPassMint() external payable mintIsActive {
        require(msg.value >= proPrice, "Not enough funds.");
        _mintSync(_msgSender(), PRO_PASS);
    }

    /// @notice Pro plus pass mint
    function proPlusPassMint() external payable mintIsActive {
        require(msg.value >= proPlusPrice, "Not enough funds.");
        _mintSync(_msgSender(), PRO_PLUS_PASS);
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        // 1, 2, 3
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(passes[_tokenId]))
            );
    }

    // @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp > liveAt && block.timestamp < expiresAt;
    }

    /**
     * @dev Check if wallet has minted
     * @param _address mint address lookup
     */
    function hasMintedFreePass(address _address) public view returns (bool) {
        return addressToFreePassMinted[_address];
    }

    // @dev Returns the starting token ID.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Sets pro price
     * @param _proPrice A base uri
     */
    function setProPrice(uint256 _proPrice) external onlyOwner {
        proPrice = _proPrice;
    }

    /**
     * @notice Sets pro plus price
     * @param _proPlusPrice A base uri
     */
    function setProPlusPrice(uint256 _proPlusPrice) external onlyOwner {
        proPlusPrice = _proPlusPrice;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets timestamps for live and expires timeframe
     * @param _liveAt A unix timestamp for live date
     * @param _expiresAt A unix timestamp for expiration date
     */
    function setMintWindow(uint256 _liveAt, uint256 _expiresAt)
        external
        onlyOwner
    {
        liveAt = _liveAt;
        expiresAt = _expiresAt;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Sets the Whitelist merkle root for the mint
     * @param _merkleRoot The merkle root to set
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * Set FxChildTunnel
     * @param _fxChildTunnel - the fxChildTunnel address
     */
    function setFxChildTunnel(address _fxChildTunnel)
        public
        override
        onlyOwner
    {
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * @notice Sets the bearz vendor item contract
     * @dev only owner call this function
     * @param _vendorContractAddress The new contract address
     */
    function setVendorContractAddress(address _vendorContractAddress)
        external
        onlyOwner
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /// @notice Withdraws funds from contract
    function withdraw() public onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "999");
    }

    /**
     * @dev Internal helper function for minting and syncing to L2
     * @param _address The amount of pro passes to mint
     * @param _passType The pass type (1,2,3)
     */
    function _mintSync(address _address, uint256 _passType) internal {
        uint256 tokenId = _nextTokenId();
        _mint(_address, 1);
        passes[tokenId] = _passType;
        _sendMessageToChild(
            abi.encode(MINTED, abi.encode(_address, tokenId, _passType))
        );
    }

    /// @dev Prevent approvals of token
    function setApprovalForAll(address, bool) public virtual override {
        revert CannotApproveAll();
    }

    /// @dev Prevent token transfer unless burning
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        if (to != address(0) && from != address(0)) {
            revert Nontransferable();
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _processRewardsClaim(bytes memory data) internal {
        (address to, uint256[] memory itemIds) = abi.decode(
            data,
            (address, uint256[])
        );
        vendorContract.dropItems(to, itemIds);
    }

    /// @dev TEST
    //    function _processMessageFromChildTest(bytes memory message)
    //        external
    //        onlyOwner
    //    {
    //        (bytes32 syncType, bytes memory syncData) = abi.decode(
    //            message,
    //            (bytes32, bytes)
    //        );
    //        if (syncType == REWARDS_CLAIM) {
    //            _processRewardsClaim(syncData);
    //        } else {
    //            revert("INVALID_SYNC_TYPE");
    //        }
    //    }

    function _processMessageFromChild(bytes memory message) internal override {
        (bytes32 syncType, bytes memory syncData) = abi.decode(
            message,
            (bytes32, bytes)
        );
        if (syncType == REWARDS_CLAIM) {
            _processRewardsClaim(syncData);
        } else {
            revert("INVALID_SYNC_TYPE");
        }
    }
}
