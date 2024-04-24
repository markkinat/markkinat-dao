// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "src/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Test, console} from "forge-std/Test.sol";
import "src/libraries/MarkkinatLibrary.sol";

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
    }

    //    struct Delegate {
    //        uint256 tokenId;
    //        uint256 proposalId;
    //        address delegate;
    //    }

    //    enum VoterDecision {
    //        Abstain,
    //        Against,
    //        For
    //    }

    uint16 public quorum;
    mapping(uint256 => Proposal) public proposals;
    uint256 private proposalCount;
    IERC721 private markkinatNFT;
    uint256 private idsAllowedToVoted = 100;
    mapping(uint256 => mapping(uint256 => bool)) private tokenVoted;
    mapping(uint256 => mapping(uint256 => bool)) private delegatedBefore;
    mapping(uint256 => mapping(address => bool)) private delegatedTo;
    mapping(uint256 => mapping(address => uint256)) private delegatedToTokenId;
    mapping(uint256 => mapping(address => bool)) private hasVoted;
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) private delegatedVote;

    event ProposalCreated(uint256 indexed, address indexed);
    event VotedSuccessfully(uint256 indexed, address, MarkkinatLibrary.VoterDecision);
    event DelegatedVotingPowerSuccessfully(address, uint256, address);

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
        require(_deadLine > block.timestamp, "Deadline must be greater than current time");
        uint256 proposalId = ++proposalCount;
        Proposal storage proposal = proposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.creator = msg.sender;
        proposal.name = _name;
        proposal.description = desc;
        proposal.deadLine = block.timestamp + _deadLine;

        emit ProposalCreated(proposalId, msg.sender);
    }

    // TODO: user decision on the Proposal created.
    // @dev: there is need to change the weight of votes which will be gotten from the Asset contract
    function voteOnProposal(uint256 proposalId, MarkkinatLibrary.VoterDecision decision, uint256 _tokenId)
        external
        activeProposalOnly(proposalId)
        tokenIdAllowedToVote(_tokenId)
        nonReentrant
    {
        require(!tokenVoted[proposalId][_tokenId], "has already voted...");

        Proposal storage proposal = proposals[proposalId];
        bool value = delegatedTo[proposalId][msg.sender];

        tokenVoted[proposalId][_tokenId] = true;
        hasVoted[proposalId][msg.sender] = true;

        if (decision == MarkkinatLibrary.VoterDecision.For) {
            if (value) {
                proposal.forProposal += 2;
            } else {
                proposal.forProposal++;
            }
        } else if (decision == MarkkinatLibrary.VoterDecision.Against) {
            if (value) {
                proposal.againstProposal += 2;
            } else {
                proposal.againstProposal++;
            }
        } else {
            if (value) {
                proposal.abstainProposal += 2;
            } else {
                proposal.againstProposal++;
            }
        }

        if (value) {
            uint256 id = delegatedToTokenId[proposalId][msg.sender];
            address realOwner = markkinatNFT.ownerOf(id);
            proposal.votes += 2;
            tokenVoted[proposalId][id] = true;
            hasVoted[proposalId][realOwner] = true;
        } else {
            proposal.votes++;
        }
        //        proposal.voter[_tokenId] = true;
        emit VotedSuccessfully(proposalId, msg.sender, decision);
    }

    // @dev: this is yet to be decided fully on what the decision of what need to be done.
    function executeProposal(uint256 proposalId) external inactiveProposalOnly(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        if (
            proposal.forProposal >= quorum && proposal.forProposal > proposal.againstProposal
                && proposal.forProposal > proposal.abstainProposal
        ) {
            // running
        }
        proposal.executed = true;
    }

    function delegateVotingPower(address _delegate, uint256 _tokenId, uint256 proposalId)
        external
        activeProposalOnly(proposalId)
        tokenIdAllowedToVote(_tokenId)
    {
        require(markkinatNFT.ownerOf(_tokenId) == msg.sender, "Only owner can be allowed to perform this action");
        require(_delegate != address(0), "Cannot delegate vote to an address zero");
        require(!delegatedBefore[proposalId][_tokenId], "already delegated");
        require(!tokenVoted[proposalId][_tokenId], "Cannot assigned already voted asset");
        require(!delegatedTo[proposalId][_delegate], "Recipient cannot be assigned more than one delegate");
        require(!hasVoted[proposalId][msg.sender], "Already voted cannot delegate vote");
        require(!hasVoted[proposalId][_delegate], "Already voted cannot accept delegate vote");

        delegatedVote[proposalId][_delegate][_tokenId] = true;
        delegatedBefore[proposalId][_tokenId] = true;
        delegatedTo[proposalId][_delegate] = true;
        delegatedToTokenId[proposalId][_delegate] = _tokenId;

        emit DelegatedVotingPowerSuccessfully(msg.sender, proposalId, _delegate);
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
