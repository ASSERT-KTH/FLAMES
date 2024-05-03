// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./quickswap/IRouter.sol";
import "./quickswap/IPair.sol";
import "./quickswap/IStake.sol";
import "./utils/Math.sol";
/**
 * Play the save game.
 *
 */
contract GoodGhostingPolygonQuickswap is Ownable, Pausable {
    using SafeMath for uint256;
    // Controls if tokens were redeemed or not from the pool
    bool public redeemed;
    // Stores the total amount of interest received in the game.
    uint256 public totalGameInterest;
    //  total principal amount
    uint256 public totalGamePrincipal;
    // Token that players use to buy in the game - DAI
    IERC20 public immutable mtoken;
    IERC20 public immutable matoken;
    IERC20 public immutable quick;
    // quickswap router instance
    IRouter public router;
    IPair public pair;
    IStake public stakingPool;
    uint256 public immutable segmentPayment;
    uint256 public immutable lastSegment;
    uint256 public immutable firstSegmentStart;
    uint256 public immutable segmentLength;
    uint256 public immutable earlyWithdrawalFee;
    struct Player {
        address addr;
        bool withdrawn;
        uint256 mostRecentSegmentPaid;
        uint256 amountPaid;
    }
    mapping(address => Player) public players;
    // we need to differentiate the deposit amount to aave or any other protocol for each window hence this mapping segment no => total deposit amount for that
    mapping(uint256 => uint256) public segmentDeposit;
    address[] public iterablePlayers;
    address[] public winners;
    event JoinedGame(address indexed player, uint256 amount);
    event Deposit(
        address indexed player,
        uint256 indexed segment,
        uint256 amount
    );
    event Withdrawal(address indexed player, uint256 amount);
    event FundsDepositedIntoExternalPool(uint256 amount);
    event FundsRedeemedFromExternalPool(
        uint256 totalAmount,
        uint256 totalGamePrincipal,
        uint256 totalGameInterest
    );
    event WinnersAnnouncement(address[] winners);
    event EarlyWithdrawal(address indexed player, uint256 amount);
    modifier whenGameIsCompleted() {
    }
    modifier whenGameIsNotCompleted() {
    }
    /**
        Creates a new instance of GoodGhosting game
        @param _inboundCurrency Smart contract address of inbound currency used for the game.
        @param _matoken Matic Token Address.
        @param _quick Quick Token Address.
        @param _router quickswap router contract address.
        @param _pair pool address.
        @param _stakingPool Stake Contract Address.
        @param _segmentCount Number of segments in the game.
        @param _segmentLength Lenght of each segment, in seconds (i.e., 180 (sec) => 3 minutes).
        @param _segmentPayment Amount of tokens each player needs to contribute per segment (i.e. 10*10**18 equals to 10 DAI - note that DAI uses 18 decimal places).
        @param _earlyWithdrawalFee Fee paid by users on early withdrawals (before the game completes). Used as an integer percentage (i.e., 10 represents 10%).
     */
    constructor(
        IERC20 _inboundCurrency,
        IERC20 _matoken,
        IERC20 _quick,
        IRouter _router,
        IPair _pair,
        IStake _stakingPool,
        uint256 _segmentCount,
        uint256 _segmentLength,
        uint256 _segmentPayment,
        uint256 _earlyWithdrawalFee
    ) public {
    }
    function pause() external onlyOwner whenNotPaused {
    }
    function unpause() external onlyOwner whenPaused {
    }
    /**
       The quickswap musdc-mausdc staking have a staking period of 1 week.
       So to keep staking throught the game duration we need to update the staking contract so exit the position from the expired pool and staking into a new pool.
    */
    function updateStakingContract(IStake _stakingPool) external onlyOwner {
    }
    function _transferDaiToContract() internal {
    }
    /**
       Returns the min. output amount based on the slippage passed so basic formula input amount * (1- sliipage / 100)
    */
    function getMinOutputAmount(uint256 amount, uint256 slippage)
        internal
        pure
        returns (uint256)
    {
    }
    /**
       Returns the LP Token amount based on the tokens deposited in the pool
       Logic Used => https://explorer-mainnet.maticvigil.com/address/0xadbF1854e5883eB8aa7BAf50705338739e558E5b/contracts Line 488 mint() function
    */
    function getLPTokenAmount(uint256 _mtokenAmount, uint256 _matokenAmount)
        internal
        view
        returns (uint256)
    {
    }
    /**
        Returns the current segment of the game using a 0-based index (returns 0 for the 1st segment ).
        @dev solidity does not return floating point numbers this will always return a whole number
     */
    function getCurrentSegment() public view returns (uint256) {
    }
    function isGameCompleted() public view returns (bool) {
    }
    function joinGame() external whenNotPaused {
    }
    /**
       @dev Allows anyone to deposit the previous segment funds into quickswap in this case the deposit follows this logic
       Swap half of the mUSDC for maUSDC - Adding liquidity to the pool - Approving the staking contract to spend the mUSDC-maUSDC LP tokens - Stake the mUSDC-maUSDC LP tokens.
       Deposits into the protocol can happen at any moment after segment 0 (first deposit window)
       is completed, as long as the game is not completed.
    */
    function depositIntoExternalPool(uint256 _slippage)
        external
        whenNotPaused
        whenGameIsNotCompleted
    {
    }
    /**
       @dev Allows player to withdraw funds in the middle of the game with an early withdrawal fee deducted from the user's principal.
       earlyWithdrawalFee is set via constructor
    */
    function earlyWithdraw(uint256 _slippage)
        external
        whenNotPaused
        whenGameIsNotCompleted
    {
    }
    /**
        Reedems funds from external pool and calculates total amount of interest for the game.
        @dev This method only redeems funds from the external pool, without doing any allocation of balances
             to users. This helps to prevent running out of gas and having funds locked into the external pool.
    */
    function redeemFromExternalPool(uint256 _slippage)
        public
        whenGameIsCompleted
    {
    }
    // to be called by individual players to get the amount back once it is redeemed following the solidity withdraw pattern
    function withdraw(uint256 _slippage) external {
    }
    function makeDeposit() external whenNotPaused {
        // only registered players can deposit
        require(
            !players[msg.sender].withdrawn,
            "Player already withdraw from game"
        );
        require(
            players[msg.sender].addr == msg.sender,
            "Sender is not a player"
        );
        uint256 currentSegment = getCurrentSegment();
        // User can only deposit between segment 1 and segmetn n-1 (where n the number of segments for the game).
        // Details:
        // Segment 0 is paid when user joins the game (the first deposit window).
        // Last segment doesn't accept payments, because the payment window for the last
        // segment happens on segment n-1 (penultimate segment).
        // Any segment greather than the last segment means the game is completed, and cannot
        // receive payments
        require(<FILL_ME>);
        //check if current segment is currently unpaid
        require(
            players[msg.sender].mostRecentSegmentPaid != currentSegment,
            "Player already paid current segment"
        );
        // check player has made payments up to the previous segment
        require(
            players[msg.sender].mostRecentSegmentPaid == currentSegment.sub(1),
            "Player didn't pay the previous segment - game over!"
        );
        // check if this is deposit for the last segment
        // if so, the user is a winner
        if (currentSegment == lastSegment.sub(1)) {
            winners.push(msg.sender);
        }
        emit Deposit(msg.sender, currentSegment, segmentPayment);
        //:moneybag:allow deposit to happen
        _transferDaiToContract();
    }
}