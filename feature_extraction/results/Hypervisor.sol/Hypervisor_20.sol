// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/drafts/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
/// @title Hypervisor
/// @notice A Uniswap V2-like interface with fungible liquidity to Uniswap V3
/// which allows for arbitrary liquidity provision: one-sided, lop-sided, and balanced
contract Hypervisor is IUniswapV3MintCallback, ERC20Permit, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    IUniswapV3Pool public pool;
    IERC20 public token0;
    IERC20 public token1;
    uint24 public fee;
    int24 public tickSpacing;
    int24 public baseLower;
    int24 public baseUpper;
    int24 public limitLower;
    int24 public limitUpper;
    address public owner;
    uint256 public deposit0Max;
    uint256 public deposit1Max;
    uint256 public maxTotalSupply;
    address public whitelistedAddress;
    bool public directDeposit; /// enter uni on deposit (avoid if client uses public rpc)
    uint256 public constant PRECISION = 1e36;
    bool mintCalled;
   event Deposit(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );
    event Withdraw(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );
    event Rebalance(
        int24 tick,
        uint256 totalAmount0,
        uint256 totalAmount1,
        uint256 feeAmount0,
        uint256 feeAmount1,
        uint256 totalSupply
    );
    /// @param _pool Uniswap V3 pool for which liquidity is managed
    /// @param _owner Owner of the Hypervisor
    constructor(
        address _pool,
        address _owner,
        string memory name,
        string memory symbol
    ) ERC20Permit(name) ERC20(name, symbol) {
    }
    /// @notice Deposit tokens
    /// @param deposit0 Amount of token0 transfered from sender to Hypervisor
    /// @param deposit1 Amount of token1 transfered from sender to Hypervisor
    /// @param to Address to which liquidity tokens are minted
    /// @param from Address from which asset tokens are transferred
    /// @return shares Quantity of liquidity tokens minted as a result of deposit
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to,
        address from,
        uint256[4] memory inMin
    ) nonReentrant external returns (uint256 shares) {
    }
    /// @notice Update fees of the positions
    /// @return baseLiquidity Fee of base position
    /// @return limitLiquidity Fee of limit position
    function zeroBurn() internal returns(uint128 baseLiquidity, uint128 limitLiquidity) {
    }
    /// @notice Pull liquidity tokens from liquidity and receive the tokens
    /// @param shares Number of liquidity tokens to pull from liquidity
    /// @return base0 amount of token0 received from base position
    /// @return base1 amount of token1 received from base position
    /// @return limit0 amount of token0 received from limit position
    /// @return limit1 amount of token1 received from limit position
    function pullLiquidity(
      uint256 shares,
      uint256[4] memory minAmounts
    ) external onlyOwner returns(
        uint256 base0,
        uint256 base1,
        uint256 limit0,
        uint256 limit1
      ) {
    } 
    function _baseLiquidityForShares(uint256 shares) internal view returns (uint128) {
    }
    function _limitLiquidityForShares(uint256 shares) internal view returns (uint128) {
    }
    /// @param shares Number of liquidity tokens to redeem as pool assets
    /// @param to Address to which redeemed pool assets are sent
    /// @param from Address from which liquidity tokens are sent
    /// @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
    /// @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
    // SWC-Reentrancy: L228-273
    function withdraw(
        uint256 shares,
        address to,
        address from,
        uint256[4] memory minAmounts
    ) nonReentrant external returns (uint256 amount0, uint256 amount1) {
    }
    /// @param _baseLower The lower tick of the base position
    /// @param _baseUpper The upper tick of the base position
    /// @param _limitLower The lower tick of the limit position
    /// @param _limitUpper The upper tick of the limit position
    /// @param feeRecipient Address of recipient of 10% of earned fees since last rebalance
    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address feeRecipient,
        uint256[4] memory inMin, 
        uint256[4] memory outMin
    ) nonReentrant external onlyOwner {
    }
    /// @notice Compound pending fees
    /// @return baseToken0Owed Pending fees of base token0
    /// @return baseToken1Owed Pending fees of base token1
    /// @return limitToken0Owed Pending fees of limit token0
    /// @return limitToken1Owed Pending fees of limit token1
    function compound() external onlyOwner returns (
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed,
        uint256[4] memory inMin
    ) {
    }
    /// @notice Add tokens to base liquidity
    /// @param amount0 Amount of token0 to add
    /// @param amount1 Amount of token1 to add
    function addBaseLiquidity(uint256 amount0, uint256 amount1, uint256[2] memory inMin) external onlyOwner {
    }
    /// @notice Add tokens to limit liquidity
    /// @param amount0 Amount of token0 to add
    /// @param amount1 Amount of token1 to add
    function addLimitLiquidity(uint256 amount0, uint256 amount1, uint256[2] memory inMin) external onlyOwner {
    }
    /// @notice Add Liquidity
    function addLiquidity(
        int24 tickLower,
        int24 tickUpper,
        address payer,
        uint256 amount0,
        uint256 amount1,
        uint256[2] memory inMin
    ) internal {        
    }
    /// @notice Adds the liquidity for the given position
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param liquidity The amount of liquidity to mint
    /// @param payer Payer Data
    /// @param amount0Min Minimum amount of token0 that should be paid
    /// @param amount1Min Minimum amount of token1 that should be paid
    function _mintLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address payer,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal {
    }
    /// @notice Burn liquidity from the sender and collect tokens owed for the liquidity
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param liquidity The amount of liquidity to burn
    /// @param to The address which should receive the fees collected
    /// @param collectAll If true, collect all tokens owed in the pool, else collect the owed tokens of the burn
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function _burnLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address to,
        bool collectAll,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal returns (uint256 amount0, uint256 amount1) {
    }
    /// @notice Get the liquidity amount for given liquidity tokens
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param shares Shares of position
    /// @return The amount of liquidity toekn for shares
    function _liquidityForShares(
        int24 tickLower,
        int24 tickUpper,
        uint256 shares
    ) internal view returns (uint128) {
    }
    /// @notice Get the info of the given position
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @return liquidity The amount of liquidity of the position
    /// @return tokensOwed0 Amount of token0 owed
    /// @return tokensOwed1 Amount of token1 owed
    function _position(int24 tickLower, int24 tickUpper)
        internal
        view
        returns (
            uint128 liquidity,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
    }
    /// @notice Callback function of uniswapV3Pool mint
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
    }
    /// @return total0 Quantity of token0 in both positions and unused in the Hypervisor
    /// @return total1 Quantity of token1 in both positions and unused in the Hypervisor
    function getTotalAmounts() public view returns (uint256 total0, uint256 total1) {
    }
    /// @return liquidity Amount of total liquidity in the base position
    /// @return amount0 Estimated amount of token0 that could be collected by
    /// burning the base position
    /// @return amount1 Estimated amount of token1 that could be collected by
    /// burning the base position
    function getBasePosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
    }
    /// @return liquidity Amount of total liquidity in the limit position
    /// @return amount0 Estimated amount of token0 that could be collected by
    /// burning the limit position
    /// @return amount1 Estimated amount of token1 that could be collected by
    /// burning the limit position
    function getLimitPosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
    }
    /// @notice Get the amounts of the given numbers of liquidity tokens
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param liquidity The amount of liquidity tokens
    /// @return Amount of token0 and token1
    function _amountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256, uint256) {
    }
    /// @notice Get the liquidity amount of the given numbers of token0 and token1
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0
    /// @param amount0 The amount of token1
    /// @return Amount of liquidity tokens
    function _liquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128) {
    }
    /// @return tick Uniswap pool's current price tick
    function currentTick() public view returns (int24 tick) {
    }
    function _uint128Safe(uint256 x) internal pure returns (uint128) {
    }
    /// @param _address Array of addresses to be appended
    function setWhitelist(address _address) external onlyOwner {
    }
    /// @notice Remove Whitelisted
    function removeWhitelisted() external onlyOwner {
    }
    /// @notice Toggle Direct Deposit
    function toggleDirectDeposit() external onlyOwner {
    }
    function transferOwnership(address newOwner) external onlyOwner {
        require(<FILL_ME>);
        owner = newOwner;
    }
    modifier onlyOwner {
    }
}