// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/contracts/MarkkinatGovernance.sol";

contract DeployMarkkinatGovernance is Script {
    address DAO_ADDRESS = 0xee53D67596baf6c437D399493Ac0499A1459c626;

    address NFT_ADDRESS = ; // TODO Add deployed NFT comtract
    uint16 quorum = ; // TODO Add quorum

    function setUp() public {}

    function run() external returns (MarkkinatGovernance) {
        vm.startBroadcast();

        MarkkinatGovernance markkinatGovernance = new MarkkinatGovernance(NFT_ADDRESS, quorum, DAO_ADDRESS);

        vm.stopBroadcast();
        return MarkkinatGovernance;
    }
}
