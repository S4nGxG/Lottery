// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Lottery} from "../../src/lottery.sol";

contract LotteryTest is Test {
    Lottery public lottery;

    uint256 public constant FEE = 1 ether;
    uint256 public constant INTERVAL = 5 minutes;
    uint256 public constant BALANCE = 10 ether;

    address public Player1 = makeAddr("player1");
    address public Player2 = makeAddr("player2");

    function setUp() external {
        lottery = new Lottery(FEE, INTERVAL);

        vm.deal(Player1, BALANCE);
        vm.deal(Player2, BALANCE);
    }

    function testEntranceIsSet() public view {
        assertEq(FEE, lottery.getEntranceFee());
    }

    function testPlayerCanEnterLottery() public {
        vm.prank(Player1);
        lottery.enterLottery{value: FEE}();

        address payable[] memory players = lottery.getPlayers();

        assertEq(players[0], Player1);
        assertEq(lottery.getPrizePool(), FEE);
    }

    function testRevertIfEntranceFeeIsWrong() public {
        vm.prank(Player1);
        vm.expectRevert(Lottery.Lottery_NotEnoughEth.selector);

        lottery.enterLottery{value: 0.5 ether}();
    }

    function testRefundIfEnoughPlayer() public {
        vm.prank(Player1);
        lottery.enterLottery{value: FEE}();

        vm.prank(Player2);
        lottery.enterLottery{value: FEE}();

        vm.warp(block.timestamp + INTERVAL + 1);
        vm.prank(Player1);
        vm.expectRevert(Lottery.Lottery_EnoughPlayers.selector);
        lottery.refund();
    }

    function testRefundIfNotEnoughPlayer() public {
        vm.prank(Player1);
        lottery.enterLottery{value: FEE}();

        uint256 playerBalanceBefore = Player1.balance;

        vm.warp(block.timestamp + INTERVAL + 1);
        vm.prank(Player1);
        lottery.refund();

        address payable[] memory players = lottery.getPlayers();

        assertEq(Player1.balance, playerBalanceBefore + FEE);
        assertEq(players.length, 0);
        assertEq(lottery.getPrizePool(), 0);
    }

    function testRefundRevertIfTimeNotUp() public {
        vm.warp(block.timestamp + INTERVAL - 1);
        vm.prank(Player1);

        lottery.enterLottery{value: FEE}();

        vm.prank(Player1);
        vm.expectRevert(Lottery.Lottery_TimeNotUp.selector);

        lottery.refund();
    }

    function testRefundRevertsIfCallerIsNotPlayer() public {
        vm.warp(block.timestamp + INTERVAL + 1);
        vm.prank(Player1);

        lottery.enterLottery{value: FEE}();

        vm.prank(Player2);
        vm.expectRevert(Lottery.Lottery_NotPlayer.selector);

        lottery.refund();
    }

    function testRefundRevertIfNoPlayer() public {
        vm.warp(block.timestamp + INTERVAL + 1);
        vm.prank(Player1);
        vm.expectRevert(Lottery.Lottery_NoPlayer.selector);

        lottery.refund();
    }
}
