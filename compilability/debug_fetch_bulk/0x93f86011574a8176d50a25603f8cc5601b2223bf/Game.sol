pragma solidity 0.4.24;
import "./PaintsPool.sol";
import "./PaintDiscount.sol";
import "./Modifiers.sol";
import "./Utils.sol";

contract Game is PaintDiscount, PaintsPool, Modifiers {
    using SafeMath for uint;

     //function estimating call price for given color
    function estimateCallPrice(uint[] _pixels, uint _color) public view returns (uint totalCallPrice) {

        uint moneySpent = moneySpentByUserForColor[_color][msg.sender];
        bool hasDiscount = hasPaintDiscountForColor[_color][msg.sender];
        uint discount = usersPaintDiscountForColor[_color][msg.sender];
        
        for (uint i = 0; i < _pixels.length; i++) {
            
            uint discountCallPrice = (nextCallPriceForColor[_color].mul(100 - discount)).div(100);
            
            if (hasDiscount == true) 
                uint price = discountCallPrice;
            else
                price = nextCallPriceForColor[_color]; 

            totalCallPrice += price;
            moneySpent += price;

            if (moneySpent >= 1 ether) {
                
                hasDiscount = true;
                discount = moneySpent / 1 ether;
                
                if (moneySpent >= 10 ether)
                    discount = 10;
            }
            
        }   
    }

    function drawTimeBank() public {

        uint lastPaintTime = lastPaintTimeForRound[currentRound];
        require ((now - lastPaintTime) > 20 minutes && lastPaintTime != 0, "20 minutes have not passed yet.");

        
        winnerOfRound[currentRound] = lastPainterForRound[currentRound];

        //timebank(1) was drawn for this round
        winnerBankForRound[currentRound] = 1; 
        //10% of time bank goes to next round
        timeBankForRound[currentRound + 1] = timeBankForRound[currentRound].div(10); 
        //45% of time bank goes to every participant in a round
        timeBankForRound[currentRound] = timeBankForRound[currentRound].mul(45).div(100); 
        //color bank goes to next round
        colorBankForRound[currentRound + 1] = colorBankForRound[currentRound]; 
        
        colorBankForRound[currentRound] = 0; 
       
        emit TimeBankPlayed(winnerOfRound[currentRound], currentRound);

        isTBPDistributable = true;
        isGamePaused = true;
        timeBankDrawnForRound[currentRound] = true;

    }

    
    function paint(uint[] _pixels, uint _color, string _refLink) external payable isRegistered(_refLink) isLiveGame() {

        require(msg.value == estimateCallPrice(_pixels, _color), "Wrong call price");
        require(_color > 0 && _color <= totalColorsNumber, "The color with such id does not exist."); 

        // bytes32 refLink32 = Utils.toBytes32(_refLink);
        // require(keccak256(abi.encodePacked(_refLink)) == keccak256(abi.encodePacked()) || refLinkExists[refLink32] == true, "No such referral link exists.");
        
       //check whether 20 minutes passed since last paint 
        if ((now - lastPaintTimeForRound[currentRound]) > 20 minutes && 
            lastPaintTimeForRound[currentRound] != 0 && 
            timeBankDrawnForRound[currentRound] == false) {

            drawTimeBank();
            msg.sender.transfer(msg.value);

        }
        
        else {
            //distribute money to banks and dividends
            _setBanks(_color);

            //paint pixels
            for (uint i = 0; i < _pixels.length; i++) {
                _paint(_pixels[i], _color);
            }
            
            
            _distributeDividends(_color, _refLink);
        
            //save user spended money for this color
            _setMoneySpentByUserForColor(_color); 
            
           
            _setUsersPaintDiscountForColor(_color);

            if (paintsCounterForColor[_color] == 0) {
                paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color] - 1] = now;
            }

            paintsCounter++; //counter for all users paints
            paintsCounterForColor[_color] ++; //counter for given color
            counterToPainter[paintsCounter] = msg.sender; //counter for given user
            counterToPainterForColor[_color][paintsCounterForColor[_color]] = msg.sender; 

            if (isUserCountedForRound[currentRound][msg.sender] == false) {
                usersCounterForRound[currentRound] = usersCounterForRound[currentRound].add(1);
                isUserCountedForRound[currentRound][msg.sender] = true;
            }
        }

    }   

    
    function _paint(uint _pixel, uint _color) internal {

        //set paints amount in a pool and price for paint
        _fillPaintsPool(_color);
        
        require(msg.sender == tx.origin);

        require(_pixel > 0 && _pixel <= totalPixelsNumber, "The pixel with such id does not exist.");

       
     
        uint oldColor = pixelToColorForRound[currentRound][_pixel];
    
        
        pixelToColorForRound[currentRound][_pixel] = _color; 
            
        //save old color for pixel
        pixelToOldColorForRound[currentRound][_pixel] = oldColor; 
                
      
        lastPaintTimeForRound[currentRound] = now; 
    
       
        lastPainterForRound[currentRound] = msg.sender;
                
       
        if (colorToPaintedPixelsAmountForRound[currentRound][oldColor] > 0) 
            colorToPaintedPixelsAmountForRound[currentRound][oldColor] = colorToPaintedPixelsAmountForRound[currentRound][oldColor].sub(1); 
    
        
        colorToPaintedPixelsAmountForRound[currentRound][_color] = colorToPaintedPixelsAmountForRound[currentRound][_color].add(1); 

        //increase paints amount for given color for color team iteration
        colorToTotalPaintsForCBIteration[cbIteration][_color] = colorToTotalPaintsForCBIteration[cbIteration][_color].add(1);

        
        totalPaintsForRound[currentRound] = totalPaintsForRound[currentRound].add(1); 

        pixelToPaintTimeForRound[currentRound][_pixel] = now;

       
        if (lastPaintTimeOfUser[msg.sender] != 0 && now - lastPaintTimeOfUser[msg.sender] < 24 hours) 
            timeBankShare[tbIteration][msg.sender]++;
            
        else    
            timeBankShare[tbIteration][msg.sender] = 1;

        
        if (lastPaintTimeOfUserForColor[_color][msg.sender] != 0 && now - lastPaintTimeOfUserForColor[_color][msg.sender] < 24 hours) 
            colorBankShare[cbIteration][_color][msg.sender]++;

        else 
            colorBankShare[cbIteration][_color][msg.sender] = 1;

        lastPaintTimeOfUser[msg.sender] = now;
        lastPaintTimeOfUserForColor[_color][msg.sender] = now;
                
        //decrease paints pool by 1 
        paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]].sub(1);
        
       
        lastPaintedPixelForRound[currentRound] = _pixel;
        
        
        emit Paint(_pixel, _color, msg.sender, currentRound, now);    

        
        lastPlayedRound[msg.sender] = currentRound;
            
        //chreck wherether all pixels are the same color
        if (colorToPaintedPixelsAmountForRound[currentRound][_color] == totalPixelsNumber) {

           
            winnerColorForRound[currentRound] = _color;

            
            winnerOfRound[currentRound] = lastPainterForRound[currentRound];        
            //color bank(2)
            winnerBankForRound[currentRound] = 2;
            //10% goes to next round  
            colorBankForRound[currentRound + 1] = colorBankForRound[currentRound].div(10); 
            //45% for color team 
            colorBankForRound[currentRound] = colorBankForRound[currentRound].mul(45).div(100);
            //timebank goes to next round
            timeBankForRound[currentRound + 1] = timeBankForRound[currentRound];
            timeBankForRound[currentRound] = 0;     
            emit ColorBankPlayed(winnerOfRound[currentRound], currentRound);  
            
            isGamePaused = true;
            isCBPDistributable = true;
            //distributeCBP();
        }
    }

    
    function _setBanks(uint _color) private {
        
        colorBankToColorForRound[currentRound][_color] = colorBankToColorForRound[currentRound][_color].add(msg.value.mul(40).div(100));

        //40% to color colorBank
        colorBankForRound[currentRound] = colorBankForRound[currentRound].add(msg.value.mul(40).div(100));

        //40% to timebank
        timeBankForRound[currentRound] = timeBankForRound[currentRound].add(msg.value.mul(40).div(100));

        //20% goes to dividends 
        dividendsBank = dividendsBank.add(msg.value.div(5)); 
    }

    
    function _distributeDividends(uint _color, string _refLink) internal {
        
        //require(ownerOfColor[_color] != address(0), "There is no such color");
        bytes32 refLink32 = Utils.toBytes16(_refLink);
    
        //if  reflink provided
        if (refLinkExists[refLink32] == true) { 

            //25% goes to founders
            pendingWithdrawals[founders] = pendingWithdrawals[founders].add(dividendsBank.div(4)); 

            //25% owner of color
            pendingWithdrawals[ownerOfColor[_color]] += dividendsBank.div(4);
            //25% owner of pixel
            pendingWithdrawals[ownerOfPixel] += dividendsBank.div(4);

            //25% to referal
            pendingWithdrawals[refLinkToUser[refLink32]] += dividendsBank.div(4);
            dividendsBank = 0;
        }

        else {

            pendingWithdrawals[founders] = pendingWithdrawals[founders].add(dividendsBank.div(3)); 
            pendingWithdrawals[ownerOfColor[_color]] += dividendsBank.div(3);
            pendingWithdrawals[ownerOfPixel] += dividendsBank.div(3);
            dividendsBank = 0;
        }
    }

    modifier isRegistered(string _refLink) {
      
        if (isRegisteredUser[msg.sender] != true) {
            bytes32 refLink32 = Utils.toBytes16(_refLink);
             
            if (refLinkExists[refLink32]) { 
                address referrer = refLinkToUser[refLink32];
                referrerToReferrals[referrer].push(msg.sender);
                referralToReferrer[msg.sender] = referrer;
                hasReferrer[msg.sender] = true;
            }
            uniqueUsersCount = uniqueUsersCount.add(1);
            newUserToCounter[msg.sender] = uniqueUsersCount;
            registrationTimeForUser[msg.sender] = now;
            isRegisteredUser[msg.sender] = true;
        }
        _;
    }

}