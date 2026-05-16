// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Lottery is VRFConsumerBaseV2Plus {
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;

    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private startTime;

    address payable[] private players;
    address payable private organizer;
    address payable private recentWinner;

    enum Status {
        OPEN,
        CALCULATING
    }

    Status public lotteryStatus;

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        uint256 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        organizer = payable(msg.sender);
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        startTime = block.timestamp;
        lotteryStatus = Status.OPEN;
    }

    error Lottery_NotEnoughEth();
    error NotOwner();
    error Lottery_TimeNotUp();
    error Lottery_EnoughPlayers();
    error Lottery_NotEnoughPlayers();
    error Lottery_NotPlayer();
    error Lottery_RefundFailed();
    error Lottery_NotOpen();
    error Lottery_NoPlayer();
    error Lottery_NoPrizePool();
    error Lottery_TransferFailed();
    error Lottery_RoundEnded();

    event EnteredLottery(address indexed player);
    event Refunded(address indexed player, uint256 amount);
    event RequestedWinner(uint256 indexed requestId);
    event PickedWinner(address indexed winner, uint256 prize);
    event OrganizerFeePaid(address indexed organizer, uint256 fee);

    modifier onlyOpen() {
        if (lotteryStatus != Status.OPEN) {
            revert Lottery_NotOpen();
        }
        _;
    }

    modifier intervalPass() {
        if (block.timestamp - startTime < i_interval) {
            revert Lottery_TimeNotUp();
        }
        _;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayers() public view returns (address payable[] memory) {
        if (organizer != payable(msg.sender)) {
            revert NotOwner();
        }
        return players;
    }

    function getPrizePool() public view returns (uint256) {
        return address(this).balance;
    }

    function getRecentWinner() public view returns (address) {
        return recentWinner;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getOrganizer() public view returns (address) {
        return organizer;
    }

    function getPlayersLength() public view returns (uint256) {
        return players.length;
    }

    function enterLottery() external payable {
        if (lotteryStatus != Status.OPEN) {
            revert Lottery_NotOpen();
        }
        if (block.timestamp - startTime >= i_interval) {
            revert Lottery_RoundEnded();
        }
        if (msg.value != i_entranceFee) {
            revert Lottery_NotEnoughEth();
        }
        players.push(payable(msg.sender));
        emit EnteredLottery(msg.sender);
    }

    function refund() public onlyOpen intervalPass {
        if (players.length >= 2) {
            revert Lottery_EnoughPlayers();
        }
        if (players.length == 0) {
            revert Lottery_NoPlayer();
        }
        if (msg.sender != players[0]) {
            revert Lottery_NotPlayer();
        }

        uint256 refundAmount = i_entranceFee;

        delete players;
        startTime = block.timestamp;

        (bool success,) = payable(msg.sender).call{value: refundAmount}("");
        if (!success) {
            revert Lottery_RefundFailed();
        } else {
            emit Refunded(msg.sender, refundAmount);
        }
    }

    function _requestRandomWords() private returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
    }

    function requestWinner() public onlyOpen intervalPass {
        if (players.length < 2) {
            revert Lottery_NotEnoughPlayers();
        }
        if (address(this).balance == 0) {
            revert Lottery_NoPrizePool();
        }

        lotteryStatus = Status.CALCULATING;
        uint256 requestId = _requestRandomWords();

        emit RequestedWinner(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % players.length;
        address payable winner = players[winnerIndex];

        uint256 prizePool = address(this).balance;
        uint256 winnerPrize = (prizePool * 90) / 100;
        uint256 organizerFee = prizePool - winnerPrize;

        recentWinner = winner;
        delete players;
        startTime = block.timestamp;
        lotteryStatus = Status.OPEN;

        (bool winnerSuccess,) = winner.call{value: winnerPrize}("");
        if (!winnerSuccess) {
            revert Lottery_TransferFailed();
        }

        (bool organizerSuccess,) = organizer.call{value: organizerFee}("");
        if (!organizerSuccess) {
            revert Lottery_TransferFailed();
        }

        emit PickedWinner(winner, winnerPrize);
        emit OrganizerFeePaid(organizer, organizerFee);
    }
}
