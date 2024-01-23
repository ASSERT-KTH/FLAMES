// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract ReferralStorage is Ownable {

    struct Sales {
        address buyer;
        address seller;
        uint256 fee;
        uint256 date;
    }



    Sales[] _sales;

    address[] _affiliates;

    mapping (address => uint256) public _affInterest; // percentuale
    mapping (address => bool) public _isAffiliate; // affiliato o no
    mapping (address => string) public _teamName; // Team Name
    mapping (uint256 => address) public _uid; 
    mapping (address => uint256) public _uidAssign;
    mapping (address => uint256) public _invites;
    mapping (address => uint256) public _earnings;

    uint256 public _totalSold;
    uint256 public _totCommission;
    uint256 _cnt = 1;
    
    function addAffiliate(string memory _name, uint256 _percent, address _aff) public onlyOwner {
        require(_isAffiliate[_aff] == false, "Address already affiliated!");
        _teamName[_aff] = _name;
        _affInterest[_aff] = _percent;
        _isAffiliate[_aff] = true;
        _affiliates.push(_aff);
        _uid[_cnt] = _aff;
        _uidAssign[_aff] = _cnt;
        _cnt++;
    }

    function retrieveAffiliates() public view returns (address[] memory){
        return _affiliates;
    }

    function retrieveLenght() public view onlyOwner returns (uint256){
        return _affiliates.length;
    }

    function retrieveSales() public view returns (Sales[] memory) {
        return _sales;
    }


    function _withReferralSale(uint256 _amount, address _buyer, address _seller, uint256 _date) internal returns (uint256) {
        uint256 fee = _amount * _affInterest[_seller] / 100;
        _sales.push(Sales(_buyer, _seller, fee, _date));
        _invites[_seller] += 1;
        _earnings[_seller] += fee;
        _totalSold += 1;
        _totCommission += fee;
        return fee;
            }
}

    