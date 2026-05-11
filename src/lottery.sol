// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
	uint256 private immutable i_entraceFee;
	address[] private players;
	address private owner;

	constructor(uint256 entraceFee) {
		i_entraceFee = entraceFee;
		owner = msg.sender;
	}

	error Lottery_NotEnoughEth();
	error NotOwner();

	function getEntraceFee() public view returns (uint256) {
		return i_entraceFee;
	}

	function getPlayers() public view returns (address[] memory) {
		if(owner != msg.sender)
			revert NotOwner();
		return players;
	}

	function enterLottery() external payable {
		if(msg.value < i_entraceFee)
			revert Lottery_NotEnoughEth();
		
	}
	function pickWinner() public {

	}
}