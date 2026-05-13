// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
	uint256 private immutable i_entranceFee;
	uint256 private immutable i_interval;
	uint256 private startTime;
	address payable[] private players;
	address payable private owner;
	enum Status {
		OPEN, 
		CALCULATING
	}

	Status lotteryStatus;

	constructor(uint256 entranceFee, uint256 interval) {
		i_entranceFee = entranceFee;
		owner = payable(msg.sender);
		i_interval = interval;
		startTime = block.timestamp;
		lotteryStatus = Status.OPEN;
	}

	error Lottery_NotEnoughEth();
	error NotOwner();
	error Lottery_TimeNotUp();
	error Lottery_EnoughPlayers();
	error Lottery_NotPlayer();
	error Lottery_RefundFailed();
	error Lottery_NotOpen();

	event EnteredLottery(address indexed player);
	event Refunded(address indexed player, uint256 amount);

	function getEntranceFee() public view returns (uint256) {
		return i_entranceFee;
	}

	function getPlayers() public view returns (address payable[] memory) {
		if(owner != payable(msg.sender))
			revert NotOwner();
		return players;
	}

	function getPrizePool() public view returns (uint256) {
		return address(this).balance;
	}

	function enterLottery() external payable {
		if(lotteryStatus != Status.OPEN)
			revert Lottery_NotOpen();
		if(msg.value != i_entranceFee)
			revert Lottery_NotEnoughEth();
		players.push(payable(msg.sender));
		emit EnteredLottery(msg.sender);
	}

	function pickWinner() public {
		
	}

	function refund() public {
		if(lotteryStatus != Status.OPEN)
			revert Lottery_NotOpen();
		if(block.timestamp - startTime < i_interval)
			revert Lottery_TimeNotUp();
		if(players.length >= 2)
			revert Lottery_EnoughPlayers();
		if(players.length == 0)
			revert Lottery_NotPlayer();
		if(msg.sender != players[0])
			revert Lottery_NotPlayer();
		
		uint256 refundAmount = i_entranceFee;

		delete players;
		startTime = block.timestamp;

		(bool success, ) = payable(msg.sender).call{value: refundAmount}("");
		if(!success)
			revert Lottery_RefundFailed();
		else 
			emit Refunded(msg.sender, refundAmount);
	}
}
