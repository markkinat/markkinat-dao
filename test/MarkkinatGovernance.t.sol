// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/Script.sol";
import "../src/contracts/MarkkinatGovernance.sol";
import "../src/contracts/MarkkinatNFT.sol";
import "src/libraries/MarkkinatLibrary.sol";

contract MarkkinatNFTTest is Test {
    MarkkinatGovernance private markkinatGovernance;
    MarkkinatNFT private markkinatNFT;

    address owner = address(0xa);
    address B = address(0xb);
    address C = address(0xc);
    address D = address(0xd);
    address E = address(0xe);

    function setUp() public {
        markkinatNFT = new MarkkinatNFT("baseURI", owner);
        markkinatGovernance = new MarkkinatGovernance(address(markkinatNFT), 3, owner);
        fundUserEth(owner);
        fundUserEth(B);
        fundUserEth(C);
        fundUserEth(D);
        fundUserEth(E);
    }

    function testCreateProposal() external {
        runOwnerDuty();

        markkinatGovernance.createProposal("name", (3 minutes), "desc");
        (, string memory name,, address _creator,,,,,, bool executed, MarkkinatGovernance.Executed v) = markkinatGovernance.proposals(1);
        console.log("result is ", name);
        assertEq(name, "name");
        assertTrue(v == MarkkinatGovernance.Executed.PENDING);
        assertEq(_creator, owner);
        assertFalse(executed);
    }

    function testOnlyRareAssetHolderCanCreateProposal() external {
        runOwnerDuty();
        markkinatNFT.startPresale();

        switchSigner(B);
        vm.warp(5.5 minutes);
        markkinatNFT.mint{value: 0.01 ether}();
        vm.expectRevert("must own the very rare asset to create a proposal");
        markkinatGovernance.createProposal("name", 1 minutes, "desc");
    }

    function testDeadLineMustBeGreaterThanCurrentTime() external {
        runOwnerDuty();
        vm.warp(10 minutes);
        vm.expectRevert("Deadline must be greater than current time");
        markkinatGovernance.createProposal("name", 5 minutes, "desc");
    }

    function testVoteOnProposal() external {
        transferAssets();
        switchSigner(B);
        markkinatGovernance.createProposal("name", 10 minutes, "desc");

        switchSigner(C);
        markkinatGovernance.voteOnProposal(1, MarkkinatLibrary.VoterDecision.For, 3);
        vm.expectRevert("Already voted on this proposal");
        markkinatGovernance.voteOnProposal(1, MarkkinatLibrary.VoterDecision.Against, 4);

        (,,,, uint256 forProps,,,, uint256 total,,) =
            markkinatGovernance.proposals(1);
        assertEq(forProps, 1);
        assertEq(total, 1);
    }

    function testVoteOnDifferentProposals() external {
        transferAssets();
        switchSigner(B);
        markkinatGovernance.createProposal("name", 10 minutes, "desc");
        markkinatGovernance.createProposal("name1", 10 minutes, "desc");

        switchSigner(C);
        markkinatGovernance.voteOnProposal(1, MarkkinatLibrary.VoterDecision.Against, 3);
        markkinatGovernance.voteOnProposal(2, MarkkinatLibrary.VoterDecision.Against, 3);

        switchSigner(D);
        markkinatGovernance.voteOnProposal(2, MarkkinatLibrary.VoterDecision.Against, 4);
        switchSigner(E);
        markkinatGovernance.voteOnProposal(2, MarkkinatLibrary.VoterDecision.Against, 5);

        (,,,, uint256 forProps,,,, uint256 total,,) = markkinatGovernance.proposals(1);
        (,,,,, uint256 against,,, uint256 total1,,) = markkinatGovernance.proposals(2);

        assertEq(forProps, 0);
        assertEq(total, 1);

        assertEq(against, 3);
        assertEq(total1, 3);
    }

    function testDelegateVotingPower() external {
        transferAssets();

        switchSigner(B);
        markkinatGovernance.createProposal("name", 5 minutes, "desc");

        switchSigner(C);
        markkinatGovernance.voteOnProposal(1, MarkkinatLibrary.VoterDecision.For, 3);

        switchSigner(D);
        vm.expectRevert("Already voted cannot accept delegate vote");
        markkinatGovernance.delegateVotingPower(C, 4, 1);

        markkinatGovernance.delegateVotingPower(E, 4, 1);

        switchSigner(E);
        markkinatGovernance.voteOnProposal(1, MarkkinatLibrary.VoterDecision.Against, 5);

        (,,,, uint256 forProps, uint256 against,,, uint256 total,,) = markkinatGovernance.proposals(1);

        assertEq(forProps, 1);
        assertEq(against, 2);
        assertEq(total, 3);
    }

    function runOwnerDuty() private {
        switchSigner(owner);
        markkinatNFT.reserveMarkkinat();
    }

    function transferAssets() private {
        runOwnerDuty();
        markkinatNFT.safeTransferFrom(owner, B, 2);
        markkinatNFT.safeTransferFrom(owner, C, 3);
        markkinatNFT.safeTransferFrom(owner, D, 4);
        markkinatNFT.safeTransferFrom(owner, E, 5);
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
        address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))));
        vm.label(addr, name);
        return addr;
    }

    function fundUserEth(address userAdress) private {
        vm.deal(address(userAdress), 1 ether);
    }
}
