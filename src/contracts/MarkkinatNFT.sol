// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MarkkinatNFT is ERC721URIStorage {

    uint256 private tokenId = 21;
    constructor() ERC721("Markkinat DAO", "MKNDAO"){}

    function mintTo(address _tokenId, string memory _baseUri) external{
        _mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _baseUri);
    }
}