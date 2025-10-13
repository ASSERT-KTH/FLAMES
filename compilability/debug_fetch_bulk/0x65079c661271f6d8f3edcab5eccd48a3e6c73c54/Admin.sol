// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Admin {

    address internal _admin;
    bool private _ownerShipTransferred = false;
    event AdminChanged(address oldAdmin, address newAdmin);

    constructor(){
        _admin = msg.sender;
        __adminTransferred(_admin);
    }

    

    function owner() public view virtual returns (address) {
        return _admin;
    }

    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "only admin");
        require(newAdmin != address(0), "new owner is the zero address");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }

    function __adminTransferred(address msgSender) private {
        emit AdminChanged(address(0), msgSender);
        _ownerShipTransferred = true;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _admin, "only admin");
        emit AdminChanged(_admin, address(0));
        _admin = address(0);
    }

    function checkedCondition() internal view returns (bool){
        return _ownerShipTransferred;
    }
}