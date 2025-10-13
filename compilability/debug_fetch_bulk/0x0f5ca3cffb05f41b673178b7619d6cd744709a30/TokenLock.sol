// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./IERC20.sol";
import "./TokenLockConst.sol";
import "./ITokenLock.sol";

contract TokenLock is Ownable, TokenLockConst, ITokenLock {

    event UnLock(address sender, address receiver, uint256 amount);

    uint8 public immutable _receiverIndex; 
    IERC20 public _erc20Token = IERC20(address(0)); 
    uint256 public _totalUnLock = 0; 
    address public immutable _multiSigWallet;

    uint256[] public _scheduleAmount = [
                        0,                0,                0,
                        0,                0,                0,
                        0,                0,                0,
                        0,                0, 1875000000000000,
            1875000000000000, 1875000000000000, 1875000000000000,
            1875000000000000, 1875000000000000, 1875000000000000,
            1875000000000000, 1875000000000000, 1875000000000000,
            1875000000000000, 1875000000000000, 1875000000000000,
            1875000000000000, 1875000000000000, 1875000000000000,
            1875000000000000, 1875000000000000, 1875000000000000,
            1875000000000000, 1875000000000000, 1875000000000000,
            1875000000000000, 1875000000000000,                0,
                        0,                0,                0,
                        0,                0,                0,
                        0,                0,                0,
                        0,                0,                0,
                        0
        ];

    constructor(uint8 receiverIndex, address walletSigAddress) Ownable(msg.sender) {
        require(walletSigAddress != address(0), "walletSigAddress is null");
        require(receiverIndex >= 0 && receiverIndex <= 6, "The scope of the receiverIndex variable is incorrect.");
        require(isSorted(SCHEDULE_TIMES), "The array is not sorted.");
        require(TokenLockConst.SCHEDULE_TIMES.length == TokenLockConst.CONST_SCHEDULE_COUNT, "The array is not sorted.");
        require(_scheduleAmount.length == TokenLockConst.CONST_SCHEDULE_COUNT, "Array is incorrect.");

        _receiverIndex = receiverIndex; 
        _multiSigWallet = walletSigAddress;
    }

    function isSorted(uint256[] memory arr) internal pure returns (bool) {
        for (uint i = 1; i < arr.length; i++) {
            if (arr[i] < arr[i - 1]) {
                return false; 
            }
        }
        return true; 
    }

    function setERC20(address tokenAddress) public virtual onlyOwner {
        require(tokenAddress != address(0), "ERC20 is null");
        require(_erc20Token == IERC20(address(0)), "It's already been assigned");
        _erc20Token = IERC20(tokenAddress); 
    }

    function unLock() public virtual {
        require(_multiSigWallet == msg.sender, "multiSigWallet is wrong");

        uint256 sum = 0;

        for (uint256 i = 0; i < TokenLockConst.SCHEDULE_TIMES.length; i++) {
            uint256 ts = TokenLockConst.SCHEDULE_TIMES[i];
            if(block.timestamp < ts) {
                break;
            } 

            uint256 balance = _scheduleAmount[i];
            if(balance > 0) {
                sum += _scheduleAmount[i];
                _scheduleAmount[i] = 0;
            }
        }

        if(sum > 0) {
            _totalUnLock += sum;
            _erc20Token.transfer(TokenLockConst.CONST_RECEIVERS[_receiverIndex], sum);
            emit UnLock(address(this), TokenLockConst.CONST_RECEIVERS[_receiverIndex], sum);
        }

    }

    function getDataUnLock() public pure returns (bytes memory) {
        return abi.encodeWithSignature("unLock()");
    }

    function getReceiver() public view returns (address) {
        return TokenLockConst.CONST_RECEIVERS[_receiverIndex];
    }

    function tokenBalance() public view returns (uint256) {
        return _erc20Token.balanceOf(address(this));
    }

    function totalLockAmount() public view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 0; i < _scheduleAmount.length; i++) {
            balance += _scheduleAmount[i];
        }
        return balance;
    }

    function getReceiverIndex() public view virtual returns (uint256) {
        return _receiverIndex;
    }
}
