
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";


interface MarkkinatNFT {
    function reserveMarkkinat() external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract MintMarkkinatNftToken is Script {    

    address private constant owner = 0xee53D67596baf6c437D399493Ac0499A1459c626;
    address private constant dev1 = 0x17e8F7fAD364dd0F32FbCCF5c6704eeb70a75F97;
    address private constant dev2 = 0xe2Ff6a5D1Bf8D9eEB740045E1E95C2AF86438Cf3;
    address private constant dev3 = 0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC; 

    function run() external {
        vm.startBroadcast();
        MarkkinatNFT markkinatNFT = MarkkinatNFT(0x142f7bd56cF9fb568484f84424A6EE5fA3f81bE3);
        markkinatNFT.reserveMarkkinat();
        markkinatNFT.safeTransferFrom(owner, dev1, 2);
        markkinatNFT.safeTransferFrom(owner, dev2, 3);
        markkinatNFT.safeTransferFrom(owner, dev3, 4);

        vm.stopBroadcast();
    }
}