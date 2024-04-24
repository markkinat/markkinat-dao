// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/Script.sol";
import "../src/contracts/MarkkinatNFT.sol";

contract MarkkinatNFTTest is Test {
    MarkkinatNFT markkinatNFT;

    address A = address(0xa);
    address B = address(0xb);
    address C = address(0xc);
    address D = address(0xd);

    function setUp() public {
        markkinatNFT = new MarkkinatNFT("baseURI", A);
        fundUserEth(A);
        fundUserEth(B);
        fundUserEth(C);
        fundUserEth(D);
    }

    function testBaseURI() public {
        assertEq(markkinatNFT.presaleStarted(), false);
    }

    // test Presale if NFT NOT RESERVED
    function testPresaleMintNotReserved() public {
        switchSigner(B);

        vm.expectRevert();

        markkinatNFT.presaleMint();
    }

    // test Presale if presale not started
    function testPresaleMintPresaleNotStarted() public {
        switchSigner(A);
        markkinatNFT.reserveMarkkinat();
        switchSigner(B);
        vm.expectRevert();
        markkinatNFT.presaleMint();
    }

    // test presale if nft mintedOut
    function testPresaleMintNFTNoteMintedOutandCantMint() public {
        switchSigner(A);
        markkinatNFT.reserveMarkkinat();

        markkinatNFT.startPresale();
        switchSigner(B);
        // vm.expectRevert();
        markkinatNFT.presaleMint{value: 0.01 ether}();

        //check B nft
        uint256 bNft = checkNftBalance(B);

        switchSigner(C);
        assertEq(bNft, 1);

        vm.expectRevert();
        markkinatNFT.mint{value: 0.01 ether}();
    }

    // test presale if nft mintedOut
    function testPresaleMintNFTNotMintedOutandCanMint() public {
        switchSigner(A);
        markkinatNFT.reserveMarkkinat();

        markkinatNFT.startPresale();
        switchSigner(B);
        // vm.expectRevert();
        markkinatNFT.presaleMint{value: 0.01 ether}();

        //check B nft
        uint256 bNft = checkNftBalance(B);

        //time wrap, increase time by 6min
        vm.warp(6 minutes);

        switchSigner(C);

        markkinatNFT.mint{value: 0.01 ether}();
        uint256 CNft = checkNftBalance(B);

        assertEq(bNft, 1);
        assertEq(CNft, 1);
    }

    // test nft after Mint outr
    function testNFTMintedOut() public {
        switchSigner(A);
        markkinatNFT.reserveMarkkinat();

        markkinatNFT.startPresale();
        switchSigner(B);
        // vm.expectRevert();
        markkinatNFT.presaleMint{value: 0.01 ether}();

        //check B nft
        uint256 bNft = checkNftBalance(B);

        //time wrap, increase time by 6min
        vm.warp(6 minutes);

        switchSigner(C);

        //wrrite a loop to run 99 time siwtching signner and public mint
        for (uint i = 1; i < 80; i++) {
            // console.log("current iteration", i);
            fundUserEth(C);

            markkinatNFT.mint{value: 0.01 ether}();
        }

        assertEq(bNft, 1);

        switchSigner(D);

        vm.expectRevert();
        markkinatNFT.mint{value: 0.01 ether}();
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

    function checkNftBalance(address userAddy) private returns (uint256) {
        return markkinatNFT.balanceOf(userAddy);
    }

    function fundUserEth(address userAdress) public {
        vm.deal(address(userAdress), 0.5 ether);
    }
}
