// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/lottery.sol";

contract DeployLottery is Script {
    uint256 public constant FEE = 0.01 ether;
    uint256 public constant INTERVAL = 5 minutes;
    address public constant VRF_COORDINATOR = address(1);
    uint256 public constant SUBSCRIPTION_ID = 0;
    bytes32 public constant KEY_HASH = bytes32(0);
    uint32 public constant CALLBACK_GAS_LIMIT = 500_000;

    function run() external returns (Lottery) {
        vm.startBroadcast();
        Lottery lottery = new Lottery(FEE, INTERVAL, VRF_COORDINATOR, SUBSCRIPTION_ID, KEY_HASH, CALLBACK_GAS_LIMIT);
        vm.stopBroadcast();

        return lottery;
    }
}
