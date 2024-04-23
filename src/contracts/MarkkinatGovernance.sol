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

    constructor(
        address nftAddress,
        uint16 _quorum,
        address initialOwner
    ) payable Ownable(initialOwner) {
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
        require(status, "must own the very rare Nft to create a proposal");
        _;
    }

    // Create a modifier which only allows a function to be
    // called if the given proposal's deadline has not been exceeded yet
    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadLine >= block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    // Create a modifier which only allows a function to be
    // called if the given proposals' deadline HAS been exceeded
    // and if the proposal has not yet been executed
    modifier inactiveProposalOnly(uint256 proposalId) {
        require(
            proposals[proposalId].deadLine <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalId].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    modifier canParticipateInProposal(uint256 _tokenId){
//        require(markkinatNFT.ownerOf(_tokenId) == msg.sender, "Not owner of this asset");
        require(_tokenId <= idsAllowedToVoted, "Provided asset not allowed to participate in proposal or Vote");
        _;
    }

    function createProposal(
        string memory _name,
        uint256 _deadLine,
        string memory desc
    ) external onlyNftHolder {
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

    function voteOnProposal(uint256 proposalId, VoterDecision decision, uint256 _tokenId) external activeProposalOnly(proposalId){
        Proposal storage proposal = proposals[proposalId];
        require(proposal.voter[_tokenId] == false, "ALREADY_VOTED");
        if(decision == VoterDecision.For){
            proposal.forProposal++;
        }
        else if (decision == VoterDecision.Against){
            proposal.againstProposal++;
        }
        else {
            proposal.abstainProposal++;
        }
        proposal.votes++;
        proposal.voter[_tokenId] = true;
    }

    function executeProposal(uint256 proposalId) external {

    }

    function delegateVotingPower(address _delegate, uint256 _tokenId) external {

    }

    function updateAllowedIdToVote(uint256 num) external onlyOwner{
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
