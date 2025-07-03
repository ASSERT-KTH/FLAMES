/*
 * @source: etherscan.io 
 * @author: -
 * @vulnerable_at_lines: 54
 */

pragma solidity ^0.4.19;

contract BANK_SAFE
{
    mapping (address=>uint256) public balances;   
   
    uint public MinSum;
    
    LogFile Log;
    
    bool intitalized;
    
    function SetMinSum(uint _val)
    public
    {
        if(intitalized)throw;
        MinSum = _val;
    }
    
    function SetLogFile(address _log)
    public
    {
        if(intitalized)throw;
        Log = LogFile(_log);
    }
    
    function Initialized()
    public
    {
        intitalized = true;
    }
    
    function Deposit()
    public
    payable
    {
        balances[msg.sender]+= msg.value;
        Log.AddMessage(msg.sender,msg.value,"Put");
    }
    
    function Collect(uint _am)
    public
    payable
    {
        if(balances[msg.sender]>=MinSum && balances[msg.sender]>=_am)
        {
require(_am<=address(this).balance);
            if(msg.sender.call.value(_am)())
            {
                balances[msg.sender]-=_am;
                Log.AddMessage(msg.sender,_am,"Collect");
            }
        }
require(false); //injected CONTRACT AFFECTED BY MINERS
    }
    
    function GetBalance()
    public
    constant
    returns(uint)
    {
        return balances[msg.sender];
    }
    
    function GetMinSum()
    public
    constant
    returns(uint)
    {
        return MinSum;
    }
    
    function GetHistory()
    public
    constant
    returns(bytes32[])
    {
        bytes32[] memory bts;
        for(uint i=0;i<History.length;i++)
        {
            bts.push(History[i].Data);
        }
        return bts;
    }
    
    function GetHistoryLen()
    public
    constant
    returns(uint)
    {
        return History.length;
    }
    
    function GetLastMsg()
    public
    constant
    returns(bytes32)
    {
        return LastMsg.Data;
    }
    
    function GetLastMsgSender()
    public
   );
    }
    
    function() 
    public 
    payable
    {
        Deposit();
    }
    
}



contract LogFile
{
    struct Message
    {
        address Sender;
        string  Data;
        uint Val;
        uint  Time;
    }
    
    Message[] public History;
    
    Message LastMsg;
    
    function AddMessage(address _adr,uint _val,string _data)
    public
    {
        LastMsg.Sender = _adr;
        LastMsg.Time = now;
        LastMsg.Val = _val;
        LastMsg.Data = _data;
        History.push(LastMsg);
    }
}