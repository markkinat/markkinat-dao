// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "src/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract MarkkinatGovernance is Ownable, ReentrancyGuard {
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
//        mapping() delegated
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

    uint16 public quorum;
    mapping(uint256 => Proposal) private proposals;
    mapping(address => Delegate) private delegate;
    uint256 private proposalCount;
    IERC721 private markkinatNFT;
    uint256 private idsAllowedToVoted;
    mapping (uint => mapping (uint => bool)) private tokenVoted;
    mapping (uint => mapping(uint => bool)) private delegatedBefore;
    mapping (uint => mapping (address => bool)) private delegatedTo;
    mapping (uint => mapping (address => uint)) private delegatedToTokenId;
    mapping (uint => mapping (address => mapping (uint => bool))) private delegatedVote;

    constructor(address nftAddress, uint16 _quorum, address initialOwner) payable Ownable(initialOwner) {
        quorum = _quorum;
        markkinatNFT = IERC721(nftAddress);
    }

    modifier onlyNftHolder() {
        bool status;
        for (uint8 i = 1; i <= 20; i++) {
            if (markkinatNFT.ownerOf(i) == msg.sender) {
                status = true;
                break;
            }
        }
        require(status, "must own the very rare asset to create a proposal");
        _;
    }

    // Create a modifier which only allows a function to be
    // called if the given proposal's deadline has not been exceeded yet
    modifier activeProposalOnly(uint256 proposalIndex) {
        require(proposals[proposalIndex].deadLine >= block.timestamp, "DEADLINE_EXCEEDED");
        _;
    }

    // Create a modifier which only allows a function to be
    // called if the given proposals' deadline HAS been exceeded
    // and if the proposal has not yet been executed
    modifier inactiveProposalOnly(uint256 proposalId) {
        require(proposals[proposalId].deadLine <= block.timestamp, "DEADLINE_NOT_EXCEEDED");
        require(proposals[proposalId].executed == false, "PROPOSAL_ALREADY_EXECUTED");
        _;
    }

    modifier tokenIdAllowedToVote(uint256 _tokenId) {
        //        require();
        // TODO: ensure that the tokenId provided is allowed to vote.
        require(_tokenId <= idsAllowedToVoted, "The provided asset is not allowed to vote");
        _;
    }

    // TODO: create a proposal
    // @dev: there is a need to take an extra argument which is to perform the action of the marketPlace contract...
    function createProposal(string memory _name, uint256 _deadLine, string memory desc) external onlyNftHolder {
        require(bytes(_name).length > 0, "Proposal name cannot be empty");
        require(bytes(desc).length > 0, "Proposal description cannot be empty");
        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.creator = msg.sender;
        proposal.name = _name;
        proposal.description = desc;
        proposal.deadLine = block.timestamp + _deadLine;
    }

    // TODO: user decision on the Proposal created.
    // @dev: there is need to change the weight of votes which will be gotten from the Asset contract
    function voteOnProposal(uint256 proposalId, VoterDecision decision, uint256 _tokenId)
        external
        activeProposalOnly(proposalId)
        tokenIdAllowedToVote(_tokenId)
        nonReentrant
    {
        require(!tokenVoted[proposalId][_tokenId], "has already voted...");
        Proposal storage proposal = proposals[proposalId];
        if (decision == VoterDecision.For) {
            proposal.forProposal++;
        } else if (decision == VoterDecision.Against) {
            proposal.againstProposal++;
        } else {
            proposal.abstainProposal++;
        }
        proposal.votes++;
        tokenVoted[proposalId][_tokenId] = true;
//        proposal.voter[_tokenId] = true;
    }

    // @dev: this is yet to be decided fully on what the decision of what need to be done.
    function executeProposal(uint256 proposalId) external inactiveProposalOnly(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.forProposal >= quorum) {
            // running
        }
        proposal.executed = true;
    }

    function delegateVotingPower(address _delegate, uint256 _tokenId, uint256 proposalId) external activeProposalOnly(proposalId) tokenIdAllowedToVote(_tokenId){
        require(markkinatNFT.ownerOf(_tokenId) == msg.sender, "Only owner can be allowed to perform this action");
        require(_delegate != address(0), "Cannot delegate vote to an address zero");
        require(!delegatedBefore[proposalId][_tokenId], "already delegated");
        require(!tokenVoted[proposalId][_tokenId], "Cannot assigned already voted asset");
        delegatedVote[proposalId][_delegate][_tokenId] = true;
        delegatedTo[proposalId][_delegate] = true;
        delegatedToTokenId[proposalId][_delegate] = _tokenId;
    }

    function updateAllowedIdToVote(uint256 num) external onlyOwner {
        idsAllowedToVoted = num;
    }

    function updateQuorum(uint16 _quorum) external onlyOwner {
        quorum = _quorum;
    }

    /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}
}
