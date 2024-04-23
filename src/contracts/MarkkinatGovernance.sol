// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/interfaces/IERC721.sol";

contract MarkkinatGovernance {
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

    struct Delegate {
        uint256 tokenId;
        uint256 proposalId;
        address delegate;
    }

    enum VoterDecision {
        Abstain,
        Against,
        For
    }

    uint16 private quorum;
    address payable private owner;
    mapping(uint256 => Proposal) private proposals;
    mapping(address => Delegate) private delegate;
    uint256 private proposalCount;
    IERC721 private nftContract;

    constructor(address nftAddress, uint16 _quorum) payable {
        quorum = _quorum;
        owner = payable(msg.sender);
        nftContract = IERC721(nftAddress);
    }

    modifier onlyNftHolder{
        bool status;
        for (uint8 i = 1; i <= 20; i++) {
            if (nftContract.ownerOf(i) == msg.sender) {
                status = true;
                break;
            }
        }
        require(status, "must own the very rare Nft to create a proposal");
        _;
    }

    function createProposal(string memory _name, uint256 _deadLine, string memory desc) external onlyNftHolder {
        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.name = _name;
        proposal.description = desc;
        proposal.deadLine =  _deadLine;
    }

    function voteOnProposal(uint256 proposalId, VoterDecision decision) external {

    }

    function executeProposal() external {}

    function withdrawEther(uint256 _amount) external {}

    function updateQuorum(uint16 _quorum) external {
        quorum = _quorum;
    }

    fallback() external{}
}
