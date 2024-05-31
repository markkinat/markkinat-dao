// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/contracts/MarkkinatNFT.sol";

contract DeployMarkkinatNFT is Script {
    address DAO_ADDRESS = 0xee53D67596baf6c437D399493Ac0499A1459c626;
    //local: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    string BASEURI =
        "https://blue-clear-mole-324.mypinata.cloud/ipfs/Qmcd7BP4Ar7DwCiaFKnhi7kmebVdiLvm4TMcAB6M7dpdHS/"; // TODO Add NFT BASE URL

    function setUp() public {}

    function run() external returns (MarkkinatNFT) {
        vm.startBroadcast();

        MarkkinatNFT markkinatNFT = new MarkkinatNFT(BASEURI, DAO_ADDRESS);

        vm.stopBroadcast();
        return markkinatNFT;
    }
}
