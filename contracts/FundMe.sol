// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe{
    using SafeMathChainlink for uint256; //using-for statement
    
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;
    
    modifier onlyOwner(){
        require (msg.sender == owner);
        _;
    }
    
    constructor(address _priceFeed) public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);  
    }
    
    function fund() public payable{
        //Fund at least $50
        uint256 mimimumUSD = 50 * 10 ** 18; //50 USD in Gwei-Wei base. Wei base = 10^18
        require(getConverstionRate(msg.value) >= mimimumUSD, "You need to spend more ETH!");
        //what the ETH -> USD converstion rate is
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256){
        (,int256 answer,,,) = priceFeed.latestRoundData();
        
        return uint256(answer * 10**10);
    }
    //1000000000
    function getConverstionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount)/ 10 ** 18;
        return ethAmountInUSD;
    }

    function getEntranceFee() public view returns (uint256) {
        //minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 *  10**18;
        return (minimumUSD * precision)/ price;
    }

    
    function withdraw() public onlyOwner {
        //only contract admin/ owner should be able to withdraw
        msg.sender.transfer(address(this).balance);
        //reset balances of all funders
        for (uint256 funderIndex = 0;funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
} 