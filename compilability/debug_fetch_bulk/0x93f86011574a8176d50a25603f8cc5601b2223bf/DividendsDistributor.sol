pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./IColor.sol";
import "./Modifiers.sol";

contract DividendsDistributor is Modifiers {
    using SafeMath for uint;
    
    function claimDividends() external {
        //if users dividends=0, revert 
        require(pendingWithdrawals[msg.sender] != 0, "Your withdrawal balance is zero.");
        claimId = claimId.add(1);
        Claim memory c;
        c.id = claimId;
        c.claimer = msg.sender;
        c.isResolved = false;
        c.timestamp = now;
        claims.push(c);
        emit DividendsClaimed(msg.sender, claimId, now);
    }
    
     function withdrawFoundersComission() external onlyAdmin() returns (bool) {
        require(pendingWithdrawals[founders] != 0, "Foundrs withdrawal balance is zero.");
        uint balance = pendingWithdrawals[founders];
        pendingWithdrawals[founders] = 0;
        founders.transfer(balance);
        return true;
    }
    

    function approveClaim(uint _claimId) public onlyAdmin() {
        
        Claim storage claim = claims[_claimId];
        
        require(!claim.isResolved);
        
        address claimer = claim.claimer;

        //Checks-Effects-Interactions pattern
        uint withdrawalAmount = pendingWithdrawals[claimer];

        
        pendingWithdrawals[claimer] = 0;

        
        claimer.transfer(withdrawalAmount);
        
        //set last withdr time for user
        addressToLastWithdrawalTime[claimer] = now;
        emit DividendsWithdrawn(claimer, _claimId, withdrawalAmount);

        claim.isResolved = true;
    }

}