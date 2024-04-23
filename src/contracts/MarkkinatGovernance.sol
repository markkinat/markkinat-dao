// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "src/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarkkinatGovernance is Ownable {
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
    mapping(uint256 => Proposal) private proposals;
    mapping(address => Delegate) private delegate;
    uint256 private proposalCount;
    IERC721 private markkinatNFT;

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

    function createProposal(
        string memory _name,
        uint256 _deadLine,
        string memory desc
    ) external onlyNftHolder {
        uint256 proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.name = _name;
        proposal.description = desc;
        proposal.deadLine = _deadLine;
    }

    function voteOnProposal(
        uint256 proposalId,
        VoterDecision decision
    ) external {}

    function executeProposal() external {}

    function delegateVotingPower(address _delegate, uint256 _tokenId) external {}

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

    // Create a modifier which only allows a function to be
    // called if the given proposal's deadline has not been exceeded yet
    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadLine > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    // Create a modifier which only allows a function to be
    // called if the given proposals' deadline HAS been exceeded
    // and if the proposal has not yet been executed
    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadLine <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }
}
