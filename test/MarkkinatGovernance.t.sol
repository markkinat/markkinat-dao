
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/Script.sol";
import "../src/contracts/MarkkinatGovernance.sol";
import "../src/contracts/MarkkinatNFT.sol";

contract MarkkinatNFTTest is Test {
    struct Proposal {
        uint256 proposalId;
        string name;
        string description;
        address creator;
        uint256 forProposal;
        uint256 againstProposal;
        uint256 abstainProposal;
        mapping(uint256 => bool) voter;
        uint256 deadLine;
        uint256 votes;
        bool executed;
    }
    MarkkinatGovernance private markkinatGovernance;
    MarkkinatNFT private markkinatNFT;

    address owner = address(0xa);
    address B = address(0xb);
    address C = address(0xc);
    address D = address(0xd);

    function setUp() public {
        markkinatNFT = new MarkkinatNFT("baseURI", owner);
        markkinatGovernance = new MarkkinatGovernance(address(markkinatNFT), 3, owner);
        fundUserEth(owner);
        fundUserEth(B);
        fundUserEth(C);
        fundUserEth(D);
    }

    function testCreateProposal() external {
        switchSigner(owner);
        markkinatNFT.reserveMarkkinat();

        markkinatGovernance.createProposal("name", (3 minutes), "desc");
        (, string memory name, , address _creator,,,,,, bool executed ) = markkinatGovernance.proposals(1);
        console.log("result is ",name);
        assertEq(name, "name");
        assertEq(_creator, owner);
        assertFalse(executed);
    }

    function testOnlyRareAssetHolderCanCreateProposal() external{
        switchSigner(owner);
        markkinatNFT.reserveMarkkinat();
        markkinatNFT.startPresale();

        switchSigner(B);
        vm.warp(5.5 minutes);
        markkinatNFT.mint{value: 0.01 ether}();
        vm.expectRevert("must own the very rare asset to create a proposal");
        markkinatGovernance.createProposal("name", 1 minutes, "desc");  
    }

    function testDeadLineMustBeGreaterThanCurrentTime() external{
        switchSigner(owner);
        markkinatNFT.reserveMarkkinat();
        vm.warp(10 minutes);
        vm.expectRevert("Deadline must be greater than current time");
        markkinatGovernance.createProposal("name", 5 minutes, "desc");
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

    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

    function fundUserEth(address userAdress) private {
        vm.deal(address(userAdress), 1 ether);
    }
}
