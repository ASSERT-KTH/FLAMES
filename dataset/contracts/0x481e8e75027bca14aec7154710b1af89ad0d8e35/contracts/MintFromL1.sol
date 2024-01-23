// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.13;
import "./Price.sol";

interface Starknet {
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);
}

contract MintFromL1 {
    address starknetContract;
    address pricingContract;
    address payable public owner;

    uint256 toAddress;
    uint256 selector;

    constructor(address _starknetContract, address _owner) {
        // on goerli: 0xde29d060D45901Fb19ED6C6e959EB22d8626708e
        starknetContract = _starknetContract;
        owner = payable(_owner); 
    }

    function withdraw() public {
        // get the amount of Ether stored in this contract
        uint256 amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function setL2Data(uint256 _toAddress, uint256 _selector) public {
        require(
            msg.sender == owner,
            "You don't have the right to call this function"
        );
        toAddress = _toAddress;
        selector = _selector;
    }

    // https://github.com/starkware-libs/cairo-lang/blob/4e233516f52477ad158bc81a86ec2760471c1b65/src/starkware/starknet/eth/StarknetMessaging.sol#L100
    function purchase(
        uint256 domain,
        uint256 token_id,
        uint256 duration_days,
        uint256 resolver,
        uint256 addr
    ) public payable {
        require(
            msg.value >= Price.compute_buy_price(domain, duration_days),
            "You didn't pay enough"
        );

        uint256[] memory payload = new uint256[](5);
        payload[0] = token_id;
        payload[1] = domain;
        payload[2] = duration_days;
        payload[3] = resolver;
        payload[4] = addr;
        Starknet(starknetContract).sendMessageToL2(
            toAddress,
            selector,
            payload
        );
    }
}
