pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./StorageV1.sol";

contract PaintDiscount is StorageV1 {
    using SafeMath for uint;
    
    //saving discount for user
    function _setUsersPaintDiscountForColor(uint _color) internal {
        
        //each 1 eth = 1% discount
        usersPaintDiscountForColor[_color][msg.sender] = moneySpentByUserForColor[_color][msg.sender] / 1 ether;
        
        //max discount 10% 
        if (moneySpentByUserForColor[_color][msg.sender] >= 10 ether)
            usersPaintDiscountForColor[_color][msg.sender] = 10;
        
    }
    
    //Money spent by user buying this color  
    function _setMoneySpentByUserForColor(uint _color) internal {
        
        moneySpentByUserForColor[_color][msg.sender] += msg.value;
        moneySpentByUser[msg.sender] += msg.value;

        if (moneySpentByUserForColor[_color][msg.sender] >= 1 ether)
            hasPaintDiscountForColor[_color][msg.sender] = true;
    }
}