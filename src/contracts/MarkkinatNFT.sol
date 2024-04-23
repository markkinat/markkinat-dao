// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MarkkinatNFT is Ownable, ERC721URIStorage {
    uint256 private tokenId = 21;

    constructor(
        address initialOwner
    ) ERC721("Markkinat DAO", "MKNDAO") Ownable(initialOwner) {}

    bool public saleIsActive = false;

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mintTo(string memory _baseUri) external {
        require(saleIsActive, "Sale must be active to mint");
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _baseUri);
        tokenId++;
    }
}
