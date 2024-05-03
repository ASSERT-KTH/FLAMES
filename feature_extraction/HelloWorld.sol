pragma solidity ^0.6.7;

import "../lib/erc20.sol";
import "../lib/safe-math.sol";

import "../interfaces/jar.sol";

// Strategy Contract Basics

abstract contract StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;

    mapping(address => bool) public harvesters;

    constructor(
        address _lp,
        address _strategist,
        address _controller
    ) public {
        require(_lp != address(0));
        require(_strategist != address(0));

        lp = _lp;
        strategist = _strategist;
        controller = _controller;

        //IERC20(lp).approve(controller, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }

    // **** Modifiers **** //

    modifier onlyBenevolent {
        require(
            harvesters[msg.sender] ||
                msg.sender == controller ||
                msg.sender == strategist
        );
        _;
    }

    // **** Views **** //

    function setSushiRouter(address _sushiRouter) external {
        require(msg.sender == strategist, "!strategist");
        sushiRouter = _sushiRouter;
    }

    function setWETH(address _weth) external {
        require(msg.sender == strategist, "!strategist");
        weth = _weth;
    }

    // Withdraw partial funds, normally used withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(lp).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _feeDev = _amount.mul(withdrawalDevFundFee).div(
            withdrawalDevFundMax
        );
        IERC20(lp).safeTransfer(IController(controller).devaddr(), _feeDev);

        uint256 _feeTreasury = _amount.mul(withdrawalTreasuryFee).div(
            withdrawalTreasuryMax
        );
        IERC20(lp).safeTransfer(
            IController(controller).treasury(),
            _feeTreasury
        );

        IERC20(lp).safeTransfer(controller, _amount.sub(_feeDev).sub(_feeTreasury));
    }


    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll(address _newStrategy) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(lp).balanceOf(address(this));

        require(_newStrategy != address(0), "!newStrategy"); // additional protection so we don't burn the funds
        IERC20(lp).safeTransfer(_newStrategy, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _distributePerformanceFeesAndDeposit() internal {
        uint256 _lp = IERC20(lp).balanceOf(address(this));

        if (_lp > 0) {
            // Treasury fees
            IERC20(lp).safeTransfer(
                IController(controller).treasury(),
                _lp.mul(performanceTreasuryFee).div(performanceTreasuryMax)
            );

            // Performance fee
            IERC20(lp).safeTransfer(
                IController(controller).devaddr(),
                _lp.mul(performanceDevFee).div(performanceDevMax)
            );

            deposit();
        }
    }
}