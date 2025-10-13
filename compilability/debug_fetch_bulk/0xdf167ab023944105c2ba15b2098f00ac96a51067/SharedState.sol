// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownership.sol";
import "./SharedStruct.sol";

contract SharedState is Ownership {
    using SharedStruct for SharedStruct.FeeOverview;

    uint internal baseCreationFee = 0.1 ether;
    uint internal baseJoiningFee = 0.001 ether;
    uint internal baseJoiningPeriod = 2 minutes;
    uint internal baseActivationPeriod = 2 minutes;
    uint internal claimingPeriodEnd = 2 minutes;

    uint internal cipherHubFeePercentage = 4;
    uint internal poolCreatorFeePercentage = 6;

    function updateBaseCreationFee(uint _creationAmount) public hasAuthority {
        baseCreationFee = _creationAmount;
    }

    function updateBaseJoiningFee(uint _joiningFee) public hasAuthority {
        baseJoiningFee = _joiningFee;
    }

    function updateBaseJoiningPeriod(uint _joiningPeriod) public hasAuthority {
        baseJoiningPeriod = _joiningPeriod * (1 minutes);
    }

    function updateBaseActionPeriod(uint _activationPeriod) public hasAuthority {
        baseActivationPeriod = _activationPeriod * (1 minutes);
    }

    function updateClaimingPeriodEnd(uint _claimingPeriodEnd) public hasAuthority {
        claimingPeriodEnd = _claimingPeriodEnd * (1 minutes);
    }

    function updateCipherhubFeePercentage(uint _cipherHubFeePercentage) public hasAuthority {
        cipherHubFeePercentage = _cipherHubFeePercentage;
    }

    function updatePoolCreatorFee(uint _poolCreatorFeePercentage) public hasAuthority {
        poolCreatorFeePercentage = _poolCreatorFeePercentage;
    }

    function getFeeOverview() public view returns (SharedStruct.FeeOverview memory){
        SharedStruct.FeeOverview memory fees;
        fees.claimingPeriodEnd = claimingPeriodEnd;
        fees.activationPeriod = baseActivationPeriod;
        fees.joiningFee = baseJoiningFee;
        fees.creationFee = baseCreationFee;
        fees.joiningPeriod = baseJoiningPeriod;
        return fees;
    }
}
