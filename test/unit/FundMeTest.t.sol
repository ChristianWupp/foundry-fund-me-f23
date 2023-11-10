// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user"); // Use "prank" cheatcode, creating fake user to have msg.sender as the user always
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;

    // uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // Give ether to user using a foundry cheatcode
    }

    // Every time we run one of this tests, it will run set up and then the function being tested
    // That's why we need to repeat lines, and resets info

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        console.log(fundMe.i_owner());
        console.log(msg.sender);
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //hey, the next line, should revert!!
        // assert (This tx fails/reverts)
        // uint256 cat = 1 => This would fail cause it didn't revert, so cat = 1 = good
        fundMe.fund(); // send 0 value => Means Failure
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER); //funder = user
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw(); // Fund USER who is not the owner try to withdraw without being the owner
    }

    function testWithDrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // See balance at Start
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); // here we test the withdraw function

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0); // All money should have been withdrawn at the fundMe
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
        // We withdrew everything and should have all there
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10; // uint160 cause of new update and to use numbers to create addresses, this uint is used (same bytes)
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //loop to create more addresses
            //vm.prank new Address
            //vm.deal new Address
            hoax(address(i), SEND_VALUE); //Both vm. at the same time w this cheatcode
            fundMe.fund{value: SEND_VALUE}();
            // fund the fundMe
        }

        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        // uint256 gasStart = gasleft(); // 1000 - unique solidity function to see what's left
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // 200
        fundMe.cheaperWithdraw(); // should have spent gas?
        //vm.startPrank & vm.stopPrank is same

        // uint256 gasEnd = gasleft(); // 800
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed); //w this I can see w -vv how much gas

        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10; // uint160 cause of new update and to use numbers to create addresses, this uint is used (same bytes)
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //loop to create more addresses
            //vm.prank new Address
            //vm.deal new Address
            hoax(address(i), SEND_VALUE); //Both vm. at the same time w this cheatcode
            fundMe.fund{value: SEND_VALUE}();
            // fund the fundMe
        }

        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        // uint256 gasStart = gasleft(); // 1000 - unique solidity function to see what's left
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // 200
        fundMe.withdraw(); // should have spent gas?
        //vm.startPrank & vm.stopPrank is same

        // uint256 gasEnd = gasleft(); // 800
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed); //w this I can see w -vv how much gas

        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}

// FundMeTest contract deployed fundMe, hence we owner
// msg.sender = caller to FundMeTest
// us -> FundMeTest -> FundMe

// Won't pass, we're making a call to a contract that doesn't exist
// when we make calls to the blockchain foundry just spins up a new local one via anvil

// What to do to work w addresses outside our system?
// 1. Unit -> Testing specific part of code
// 2. Integration -> Testing how our code works w other parts of the code
// 3. Forked -> Test code on simulated real environment
// 4. Staging -> Testing our code in a real environment is not a prod
