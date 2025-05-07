// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant INITIAL_BALANCE = 10 ether;

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        DeployFundMe deployedFundMe = new DeployFundMe();
        fundMe = deployedFundMe.run();
        vm.deal(USER, INITIAL_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundfailedWithoutEnoughETH() public {
        vm.expectRevert(); // The next line should revert
        fundMe.fund();
    }

    function testFundUpdatedFundedDataStructure() public {
        vm.prank(USER); // the next tx will be sent by USER

        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFunderToArray() public {
        vm.prank(USER);

        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // The next line should revert
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        // arrange
        uint256 initialOwnerBalance = fundMe.getOwner().balance;
        uint256 initialFundMeBalance = address(fundMe).balance;

        // act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // assert
        uint256 finalOwnerBalance = fundMe.getOwner().balance;
        uint256 finalFundMeBalance = address(fundMe).balance;
        assertEq(finalFundMeBalance, 0);
        assertEq(finalOwnerBalance, initialOwnerBalance + initialFundMeBalance);
    }

    function testWithdrawWithMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
