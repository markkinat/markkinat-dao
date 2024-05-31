// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/contracts/MarkkinatGovernance.sol";

contract DeployMarkkinatGovernance is Script {
    address DAO_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    //local: 0xee53D67596baf6c437D399493Ac0499A1459c626;

    address NFT_ADDRESS = 0xaF2A5B8bF1e24045fdF26F8ae5Ea93A2c757b404;
    //local-anvil: 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    // 0x142f7bd56cF9fb568484f84424A6EE5fA3f81bE3; // TODO Add deployed NFT comtract
    uint16 quorum = 40; // TODO Add quorum

    function setUp() public {}

    function run() external returns (MarkkinatGovernance) {
        vm.startBroadcast();

        MarkkinatGovernance markkinatGovernance = new MarkkinatGovernance(
            NFT_ADDRESS,
            quorum,
            DAO_ADDRESS
        );

        vm.stopBroadcast();
        return markkinatGovernance;
    }
}
