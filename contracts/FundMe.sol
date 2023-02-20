/*
#  Get funds from user
#  Withdraw funds
#  Set a min funding value in USD
*/

// SPDX-License-Identifier: MIT

//1. Pragma
pragma solidity ^0.8.0;

//2. Imports
import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

//3. Error codes
error FundMe__NotOwner(); // Declaring an error

// 4. Interfaces, Libraries, Contracts

// 5. Using  Ethereum Natural Language Specification Format (NatSpec) in other word add comments and it also help to generate documentation
/**
 * @title A contract for crowd funding
 * @author Souvik Bhattacharjee
 * @notice This contract is to demo sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    /**Inside each contract, library or interface, use the following order:

                Type declarations

                State variables

                Events

                Errors

                Modifiers

                Functions

    Order of Functions:
                constructor

                receive function (if exists)

                fallback function (if exists)

                external

                public

                internal

                private
    */

    // i. Type Declaration
    using PriceConverter for uint256;

    // ii. State Variables
    uint256 public constant MIN_USD = 50 * 1e18; // before constant: gas - 913941 || after: gas - 891440
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner; // before constant: gas - 913941 || after: gas - 891440
    AggregatorV3Interface private s_priceFeed;

    // iii. Events, Errors, Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; //Check if requirement met and '_' represents that now executes the rest of the code
    }

    // Constructor, Receive, Fallback
    constructor(address priceFeedAdd) {
        i_owner = msg.sender; // exe cost before immutable: 2580 || exe cost after immutable: 444
        s_priceFeed = AggregatorV3Interface(priceFeedAdd);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our library
     */

    function fund() public payable {
        //Wnat to be able to set a min fund amount in USD
        //  1. How do we send ETH to this contract

        // require(getConversionRate(msg.value) >= MIN_USD, "Didn't send enough"); // 1e18 == 1 * 10 **18 == 1000000000000000000 wei as money math is done in terms of wei so 1 eth needs to be set as 1e18
        require(
            msg.value.getConversionRate(s_priceFeed) >= MIN_USD,
            "You need to spend more ETH!"
        ); // 1e18 == 1 * 10 **18 == 1000000000000000000 wei as money math is done in terms of wei so 1 eth needs to be set as 1e18

        // console.log(
        //     "Transferring from %s to %s %s tokens",
        //     msg.sender,
        //     i_owner,
        //     msg.sender
        // );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
        // console.log(
        //     "Sender balance is %s tokens",
        //     addressToAmountFunded[msg.sender]
        // );
        //msg.value has 18 decimal places
    }

    function withdraw() public onlyOwner {
        // for loop
        for (uint256 i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        // reset the array
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /** @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
