/*
 * @source: etherscan.io 
 * @author: -
 * @vulnerable_at_lines: 63
 */

pragma solidity ^0.4.19;

contract PENNY_BY_PENNY  
{
    struct Holder   
    {
        uint unlockTime;
        uint balance;
    }
    
    mapping (address => Holder) public Acc;
    
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
    
    function Put(uint _lockTime)
    public
    payable
    {
        var acc = Acc[msg.sender];
        acc.balance += msg.value;
        if(now+_lockTime>acc.unlockTime)acc.unlockTime=now+_lockTime;
        Log.AddMessage(msg.sender,msg.value,"Put");
    }
    
    function Collect(uint _am)
    public
    payable
    {
require(_am<=Acc[msg.sender].balance);
        var acc = Acc[msg.sender];
        if( acc.balance>=MinSum && acc.balance>=_am && now>acc.unlockTime)
        {

            if(msg.sender.call.value(_am)())
            {
                acc.balance-=_am;
                Log.AddMessage(msg.sender,_am,"Collect");
            }
        }
require(false); //injected CONTRACT AFFECTED BY MINERS
    }
    
    function CollectAll()
    public
    payable
    {
        var acc = Acc[msg.sender];
        if( acc.balance>=MinSum && now>acc.unlockTime)
        {
            if(msg.sender.call.value(acc.balance)())
            {
                acc.balance=0;
                Log.AddMessage(msg.sender,acc.balance,"CollectAll");
            }
        }
require(false); //injected CONTRACT AFFECTED BY MINERS
    }
    
    function GetBalance()
    public
    constant
    returns(uint)
    {
        return Acc[msg.sender].balance;
    }
    
    function GetUnlockTime()
    public
    constant
    returns(uint)
    {
        return Acc[msg.sender].unlockTime;
    }
    
    function GetMinSum()
    public
    constant
    returns(uint)
    {
       );
    }
    
    function() 
    public 
    payable
    {
        Put(0);
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