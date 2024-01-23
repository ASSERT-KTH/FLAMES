//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Interfaces.sol";
import "./BaseErc20.sol";

abstract contract AntiSniper is BaseErc20 {

    bool public enableSniperBlocking;
    bool public enableBlockLogProtection;

    uint256 public maxGasLimit;

    uint256 public launchTime;
    uint256 public launchBlock;
    uint256 public snipersCaught;
    
    mapping (address => bool) public isSniper;
    mapping (address => bool) public isNeverSniper;
    mapping (address => uint256) public transactionBlockLog;
    
    // Overrides
    
    function configure(address _owner) internal virtual override {
        isNeverSniper[_owner] = true;
        super.configure(_owner);
    }
    
    function launch() override virtual public onlyOwner {
        super.launch();
        launchTime = block.timestamp;
        launchBlock = block.number;
        emit ConfigurationChanged(msg.sender, "Anti Sniper Launched");
    }
    
    function preTransfer(address from, address to, uint256 value) override virtual internal {
        require(enableSniperBlocking == false || isSniper[msg.sender] == false, "sniper rejected");
        
        if (launched && from != owner && isNeverSniper[from] == false && isNeverSniper[to] == false) {
            
            if (maxGasLimit > 0) {
               require(gasleft() <= maxGasLimit, "this is over the max gas limit");
            }
            
            if(enableBlockLogProtection) {
                if (transactionBlockLog[to] == block.number) {
                    isSniper[to] = true;
                    snipersCaught ++;
                }
                if (transactionBlockLog[from] == block.number) {
                    isSniper[from] = true;
                    snipersCaught ++;
                }
                if (exchanges[to] == false) {
                    transactionBlockLog[to] = block.number;
                }
                if (exchanges[from] == false) {
                    transactionBlockLog[from] = block.number;
                }
            }
        }
        
        super.preTransfer(from, to, value);
    }

    
    // Admin methods
       
    function setSniperBlocking(bool enabled) external onlyOwner {
        enableSniperBlocking = enabled;
        emit ConfigurationChanged(msg.sender, "Enable/Disable Sniper Blocking");
    }
    
    function setBlockLogProtection(bool enabled) external onlyOwner {
        enableBlockLogProtection = enabled;
        emit ConfigurationChanged(msg.sender, "Enable/Disable Block Log Protection");
    }

    function setMaxGasLimit(uint256 amount) external onlyOwner {
        require(amount == 0 || amount > 200, "This gas limit is too low");
        maxGasLimit = amount;
        emit ConfigurationChanged(msg.sender, "Max Gas Limit Changed");
    }
    
    function setIsSniper(address who, bool enabled) external onlyOwner {
        isSniper[who] = enabled;
        emit ConfigurationChanged(msg.sender, "Sniper List Changed");
    }

    function setNeverSniper(address who, bool enabled) external onlyOwner {
        isNeverSniper[who] = enabled;
        emit ConfigurationChanged(msg.sender, "Never Sniper List Changed");
    }

    // private methods
}