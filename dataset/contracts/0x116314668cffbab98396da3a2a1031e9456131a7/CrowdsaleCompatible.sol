pragma solidity ^0.4.24;

import "./BasicERC20.sol";
import "./Ownable.sol";
import "./BasicCrowdsale.sol";

contract CrowdsaleCompatible is BasicERC20, Ownable
{
    BasicCrowdsale public crowdsale = BasicCrowdsale(0x0);

    // anyone can unfreeze tokens when crowdsale is finished
    function unfreezeTokens() public
    {
        assert(now > crowdsale.endTime());
        isTokenTransferable = true;
    }

    // change owner to 0x0 to lock this function
    function initializeCrowdsale(address crowdsaleContractAddress, uint256 tokensAmount) onlyOwner public  {
        transfer((address)(0x0), tokensAmount);
        allowance[(address)(0x0)][crowdsaleContractAddress] = tokensAmount;
        crowdsale = BasicCrowdsale(crowdsaleContractAddress);
        isTokenTransferable = false;
        transferOwnership(0x0); // remove an owner
    }
}