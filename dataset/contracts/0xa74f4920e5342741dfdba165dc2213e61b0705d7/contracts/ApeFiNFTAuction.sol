// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "erc721a/contracts/extensions/IERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ApeFiNFTAuction is Ownable, ReentrancyGuard, Pausable {
    uint256 public constant MINT_START_PRICE = 0.6e18; // 0.6 ETH
    uint256 public constant MINT_PRICE_DROP_INTERVAL = 4 hours;
    uint256 public constant MINT_PRICE_DROP_DEGREE = 0.1e18; // 0.1 ETH
    uint256 public constant MIN_MINT_PRICE = 0.1e18; // 0.1 ETH
    uint256 public constant MAX_MINT_PER_TX = 20;

    IERC721AQueryable public immutable apeFiNFT;

    address public deployer;
    uint256 public startTime;
    uint256 public mintIndex;

    event StartTimeSet(uint256 startTime);
    event DeployerSet(address deployer);
    event MintIndexSet(uint256 mintIndex);

    constructor(address apeFiNFT_) {
        apeFiNFT = IERC721AQueryable(apeFiNFT_);
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "contract cannot mint");
        _;
    }

    /**
     * @notice Get the public mint price.
     */
    function getMintPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - startTime;
        uint256 priceDropped = (timeElapsed / MINT_PRICE_DROP_INTERVAL) *
            MINT_PRICE_DROP_DEGREE;
        if (priceDropped >= MINT_START_PRICE - MIN_MINT_PRICE) {
            return MIN_MINT_PRICE;
        }
        return MINT_START_PRICE - priceDropped;
    }

    /**
     * @notice Get the available amount.
     * @dev This function is meant to be called off-chain.
     */
    function getAvailableAmount() public view returns (uint256) {
        uint256[] memory tokenIds = apeFiNFT.tokensOfOwnerIn(
            deployer,
            mintIndex,
            10000
        );
        return tokenIds.length;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(
        uint256 quantity
    ) external payable whenNotPaused nonReentrant onlyEOA {
        require(startTime != 0, "start time not set");
        require(block.timestamp >= startTime, "auction not started");
        require(quantity <= MAX_MINT_PER_TX, "max mint amount per tx exceeded");
        require(
            quantity <= apeFiNFT.balanceOf(deployer),
            "max available amount exceeded"
        );

        uint256 price = getMintPrice();
        require(msg.value == price * quantity, "not enough ether");

        for (uint256 i = 0; i < quantity; ) {
            while (apeFiNFT.ownerOf(mintIndex) != deployer) {
                mintIndex++;
            }
            apeFiNFT.transferFrom(deployer, msg.sender, mintIndex);

            unchecked {
                i++;
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Admin sets the start time.
     * @param _startTime The start time
     */
    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > 0, "invalid start time");
        startTime = _startTime;

        emit StartTimeSet(_startTime);
    }

    /**
     * @notice Admin sets the deployer that holds the "unminted" NFTs.
     * @param _deployer The deployer
     */
    function setDeployer(address _deployer) external onlyOwner {
        deployer = _deployer;

        emit DeployerSet(_deployer);
    }

    /**
     * @notice Admin sets the mint index.
     * @param _mintIndex The mint index
     */
    function setStartIndex(uint256 _mintIndex) external onlyOwner {
        mintIndex = _mintIndex;

        emit MintIndexSet(_mintIndex);
    }

    /**
     * @notice Admin pauses minting.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Admin unpauses minting.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Admin withdraws ether.
     */
    function withdraw() external onlyOwner {
        uint256 ethBal = address(this).balance;
        (bool sent, ) = payable(owner()).call{value: ethBal}("");
        require(sent, "failed to send ether");
    }
}
