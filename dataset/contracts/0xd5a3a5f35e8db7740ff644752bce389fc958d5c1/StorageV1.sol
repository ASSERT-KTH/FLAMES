pragma solidity 0.4.24;
import "./StorageV0.sol";
import "./IColor.sol";
import "./IPixel.sol";

contract StorageV1 is StorageV0 {

    //pixel color(round=> pixel=> color)
    mapping (uint => mapping (uint => uint)) public pixelToColorForRound; 

    //old pixel color(round=> pixel=> color)
    mapping (uint => mapping (uint => uint)) public pixelToOldColorForRound; 

    // (round => color => pixel amount)
    mapping (uint => mapping (uint => uint)) public colorToPaintedPixelsAmountForRound; 

    //color bank for round (round => color bank)
    mapping (uint => uint) public colorBankForRound; 

    //color bank for  color for round (round => color => color bank)
    mapping (uint => mapping (uint => uint)) public colorBankToColorForRound; 

    //time bank for round (round => time bank)
    mapping (uint => uint) public timeBankForRound; 
    
    // (round => timestamp)
    mapping (uint => uint) public lastPaintTimeForRound; 

    // (round => adress)
    mapping (uint => address) public lastPainterForRound; 

    
    mapping (uint => uint) public lastPaintedPixelForRound;

    // (round => color) 
    mapping (uint => uint) public winnerColorForRound; 

    // (round => color => paints amount)
    mapping (uint => mapping (uint => uint)) public colorToTotalPaintsForCBIteration; 

    // (round => adress)
    mapping (uint => address) public winnerOfRound; 

    //bank drawn in round (round => drawn bank) (1 = time bank, 2 = color bank)
    mapping (uint => uint) public winnerBankForRound; 

    
    mapping (uint => mapping (uint => uint)) public pixelToPaintTimeForRound;

   
    mapping (uint => uint) public totalPaintsForRound;
        
    
    mapping (uint => mapping (uint => uint)) public paintGenToAmountForColor;
    
    
    mapping (uint => mapping (uint => uint)) public paintGenToStartTimeForColor;
    
    
    mapping (uint => mapping (uint => uint)) public paintGenToEndTimeForColor;
    
    //bool 
    mapping (uint => mapping (uint => bool)) public paintGenStartedForColor;

   
    mapping (uint => uint) public currentPaintGenForColor;
    
   
    mapping (uint => uint) public callPriceForColor;
    
 
    mapping (uint => uint) public nextCallPriceForColor;
    
    
    mapping (uint => mapping (address => uint)) public moneySpentByUserForColor;

    
    mapping (address => uint) public moneySpentByUser;
    
    
    mapping (uint => mapping (address => bool)) public hasPaintDiscountForColor;
    
    //in percent 
    mapping (uint => mapping (address => uint)) public usersPaintDiscountForColor;

     
    mapping (address => bool) public isRegisteredUser;
    
    
    mapping (address => bool) public hasRefLink;

   
    mapping (address => address) public referralToReferrer;

    
    mapping (address => address[]) public referrerToReferrals;
    
   
    mapping (address => bool) public hasReferrer;
    
    
    mapping (address => string) public userToRefLink;
    

    mapping (bytes32 => address) public refLinkToUser;
    
    
    mapping (bytes32 => bool) public refLinkExists;
    
   
    mapping (address => uint) public newUserToCounter;
    
   
    uint public uniqueUsersCount;

   
    uint public maxPaintsInPool;

  
    uint public currentRound;

    //time bank iteration
    uint public tbIteration;

   //color bank iteration
    uint public cbIteration;

    
    uint public paintsCounter; 

    //Time Bank Iteration => Painter => Painter's Share in Time Team
    mapping (uint => mapping (address => uint)) public timeBankShare;

    //Color Bank Iteration => Color => Painter => Painter's Share in Time Team
    mapping (uint => mapping (uint => mapping (address => uint))) public colorBankShare;

   
    mapping (uint => uint) public paintsCounterForColor; 

    //cbIteration => color team
    mapping (uint => address[]) public cbTeam; 

    //tbIteration => color team 
    mapping (uint => address[]) public tbTeam;

     //counter => user
    mapping (uint => address) public counterToPainter;

    //color => counter => user    
    mapping (uint => mapping (uint => address)) public counterToPainterForColor; 

    //cbIteration => user !should not be public
    mapping (uint => mapping (address => bool)) public isInCBT; 

    //tbIteration => user !should not be public
    mapping (uint => mapping (address => bool)) public isInTBT; 

    //cbIteration => painter => color bank prize
    mapping (uint => mapping (address => uint)) public painterToCBP; 

    //tbIteration => painter => time bank prize
    mapping (uint => mapping (address => uint)) public painterToTBP; 

    //сbIteration =>  bool
    mapping (uint => bool) public isCBPTransfered;

    //tbIteration => bool
    mapping (uint => bool) public isTBPTransfered;

    
    mapping (address => uint) public lastPlayedRound;
    
    //Dividends Distribution
    mapping (uint => address) public ownerOfColor;

    mapping (address => uint) public pendingWithdrawals; 
    
    // (adress => time)
    mapping (address => uint) public addressToLastWithdrawalTime; 
    
  
    uint public dividendsBank;

    struct Claim {
        uint id;
        address claimer;
        bool isResolved;
        uint timestamp;
    }

    uint public claimId;

    Claim[] public claims;

    
    address public ownerOfPixel = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
    address public founders =0xe04f921cf3d6c882C0FAa79d0810a50B1101e2D4;

    bool public isGamePaused;
    
    bool public isCBPDistributable;
    bool public isTBPDistributable;
    
    mapping(address => bool) public isAdmin;

    Color public colorInstance;
    Pixel public pixelInstance;

    uint public totalColorsNumber; // 8
    uint public totalPixelsNumber; //225 in V1

   
    uint public refLinkPrice; 

   
    mapping (address => uint) public registrationTimeForUser;

    mapping (address => uint) public lastPaintTimeOfUser;
    mapping (uint => mapping (address => uint)) public lastPaintTimeOfUserForColor;

    mapping (uint => bool) public timeBankDrawnForRound;

    
    mapping (uint => uint) public usersCounterForRound;
 
    mapping (uint => mapping (address => bool)) public isUserCountedForRound;

   // Events

    event CBPDistributed(uint indexed round, uint indexed cbIteration, address indexed winner, uint prize);
    event DividendsWithdrawn(address indexed withdrawer, uint indexed claimId, uint indexed amount);
    event DividendsClaimed(address indexed claimer, uint indexed claimId, uint indexed currentTime);
    event Paint(uint indexed pixelId, uint colorId, address indexed painter, uint indexed round, uint timestamp);
    event ColorBankPlayed(address winnerOfRound, uint indexed round);
    event TimeBankPlayed(address winnerOfRound, uint indexed round);
    event CallPriceUpdated(uint indexed newCallPrice);
    event TBPDistributed(uint indexed round, uint indexed tbIteration, address indexed winner, uint prize);
    event EtherWithdrawn(uint balance, uint colorBank, uint timeBank, uint timestamp);
}