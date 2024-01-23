    pragma solidity ^0.4.24;

    import "./SafeMath.sol";
    import "./Ownable.sol";
    import "./BasicERC20.sol";
    
    contract BasicCrowdsale is Ownable
    {
        using SafeMath for uint256;
        BasicERC20 token;

        address public ownerWallet;
        uint256 public startTime;
        uint256 public endTime;
        uint256 public totalEtherRaised = 0;
        uint256 public minDepositAmount;
        uint256 public maxDepositAmount;

        uint256 public softCapEther;
        uint256 public hardCapEther;

        mapping(address => uint256) private deposits;

        constructor () public {

        }

        function () external payable {
            buy(msg.sender);
        }

        function getSettings () view public returns(uint256 _startTime,
            uint256 _endTime,
            uint256 _rate,
            uint256 _totalEtherRaised,
            uint256 _minDepositAmount,
            uint256 _maxDepositAmount,
            uint256 _tokensLeft ) {

            _startTime = startTime;
            _endTime = endTime;
            _rate = getRate();
            _totalEtherRaised = totalEtherRaised;
            _minDepositAmount = minDepositAmount;
            _maxDepositAmount = maxDepositAmount;
            _tokensLeft = tokensLeft();
        }

        function tokensLeft() view public returns (uint256)
        {
            return token.balanceOf(address(0x0));
        }

        function changeMinDepositAmount (uint256 _minDepositAmount) onlyOwner public {
            minDepositAmount = _minDepositAmount;
        }

        function changeMaxDepositAmount (uint256 _maxDepositAmount) onlyOwner public {
            maxDepositAmount = _maxDepositAmount;
        }

        function getRate() view public returns (uint256) {
            assert(false);
        }

        function getTokenAmount(uint256 weiAmount) public view returns(uint256) {
            return weiAmount.mul(getRate());
        }

        function checkCorrectPurchase() view internal {
            require(startTime < now && now < endTime);
            require(msg.value >= minDepositAmount);
            require(msg.value < maxDepositAmount);
            require(totalEtherRaised + msg.value < hardCapEther);
        }

        function isCrowdsaleFinished() view public returns(bool)
        {
            return totalEtherRaised >= hardCapEther || now > endTime;
        }

        function buy(address userAddress) public payable {
            require(userAddress != address(0));
            checkCorrectPurchase();

            // calculate token amount to be created
            uint256 tokens = getTokenAmount(msg.value);

            // update state
            totalEtherRaised = totalEtherRaised.add(msg.value);

            token.transferFrom(address(0x0), userAddress, tokens);

            if (totalEtherRaised >= softCapEther)
            {
                ownerWallet.transfer(this.balance);
            }
            else
            {
                deposits[userAddress] = deposits[userAddress].add(msg.value);
            }
        }

        function getRefundAmount(address userAddress) view public returns (uint256)
        {
            if (totalEtherRaised >= softCapEther) return 0;
            return deposits[userAddress];
        }

        function refund(address userAddress) public
        {
            assert(totalEtherRaised < softCapEther && now > endTime);
            uint256 amount = deposits[userAddress];
            deposits[userAddress] = 0;
            userAddress.transfer(amount);
        }
    }