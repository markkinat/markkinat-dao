// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "forge-std/Script.sol";

import "../src/contracts/MarkkinatNFT.sol";
import "../src/contracts/MarkkinatGovernance.sol";

contract MarkkinatGovernanceTest is Test {
    MarkkinatGovernance markkinatGovernance;
    MarkkinatNFT markkinatNFT;

    address DAO = address(0xdaa);
    address A = address(0xa);
    address B = address(0xb);
    address C = address(0xc);
    address D = address(0xd);

    function setUp() public {
        markkinatNFT = new MarkkinatNFT("baseURI", DAO);
        markkinatGovernance = new MarkkinatGovernance(address(markkinatNFT), 200, DAO);
        fundUserEth(A);
        fundUserEth(B);
        fundUserEth(C);
        fundUserEth(D);
    }

    function switchSigner(address _newSigner) public {
        address foundrySigner = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
        if (msg.sender == foundrySigner) {
            vm.startPrank(_newSigner);
        } else {
            vm.stopPrank();
            vm.startPrank(_newSigner);
        }
    }

    function fundUserEth(address userAdress) public {
        vm.deal(address(userAdress), 0.5 ether);
    }
}
