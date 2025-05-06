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

    function setUp() external {
        DeployFundMe deployedFundMe = new DeployFundMe();
        fundMe = deployedFundMe.run();
        vm.deal(USER, INITIAL_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.i_owner(), msg.sender);
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
}
