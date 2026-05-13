// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/lottery.sol";

contract DeployLottery is Script {
    uint256 public constant FEE = 0.01 ether;
    uint256 public constant INTERVAL = 5 minutes;

    function run() external returns (Lottery) {
        vm.startBroadcast();
        Lottery lottery = new Lottery(FEE, INTERVAL);
        vm.stopBroadcast();

        return lottery;
    }
}

