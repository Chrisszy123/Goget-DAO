//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevs.sol";
import "./IFakeNFTMarket.sol";

contract DevsDao {
    //create a mapping from proposal id to Proposal struct
    mapping(uint256 => Proposal) public proposals;
    uint256 public numOfProposal;
    address owner;
    IFakeNFTMarket fakeNftMarket;
    ICryptoDevs cryptoDevs;
    // SINCE every vote can either be Yes of No we can create an enum of votes
    enum Vote {
        Yes,
        No
    }
    // Create a struct named Proposal containing all relevant information
    struct Proposal {
        // nftTokenId - the tokenID of the NFT to purchase from FakeNFTMarketplace if the proposal passes
        uint256 nftTokenId;
        // deadline - the UNIX timestamp until which this proposal is active. Proposal can be executed after the deadline has been exceeded.
        uint256 deadline;
        // yayVotes - number of yay votes for this proposal
        uint256 yayVotes;
        // nayVotes - number of nay votes for this proposal
        uint256 nayVotes;
        // executed - whether or not this proposal has been executed yet. Cannot be executed before the deadline has been exceeded.
        bool executed;
        // voters - a mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
        mapping(uint256 => bool) voters;
    }

    // create a payable contructor that initializes the interfaces with their respective contract addresses
    constructor(address _fakeNftMarket, address _cryptoDevs) payable {
        fakeNftMarket = IFakeNFTMarket(_fakeNftMarket);
        cryptoDevs = ICryptoDevs(_cryptoDevs);
        owner = msg.sender;
    }

    //MODIFIERS

    // create a modifier that allows only people with the cryptodevs nft to call a function
    modifier onlyNftHolder() {
        require(
            cryptoDevs.balanceOf(msg.sender) > 0,
            "You dont own any NFT, not a DAO member"
        );
        _;
    }
    modifier onlyContractOwner() {
        require(msg.sender == owner, "NOT OWNER");
        _;
    }
    //active proposals
    modifier onlyActiveProposal(uint256 _proposalIndex) {
        require(
            proposals[_proposalIndex].deadline > block.timestamp,
            "Proposal is inactive"
        );
        _;
    }
    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    /// @dev createProposal allows a CryptoDevsNFT holder to create a new proposal in the DAO
    /// @param _tokenId - the tokenID of the NFT to be purchased from FakeNFTMarketplace if this proposal passes
    /// @return Returns the proposal index for the newly created proposal
    function createProposal(uint256 _tokenId)
        external
        onlyNftHolder
        returns (uint256)
    {
        require(fakeNftMarket.available(_tokenId), "NFT not Available");
        // create a new instance of the proposal struct
        Proposal storage proposal = proposals[numOfProposal];
        // set the NFT token id in the Proposal struct
        proposal.nftTokenId = _tokenId;
        // set deadline
        proposal.deadline = block.timestamp + 5 minutes;
        // increment the total number of proposals
        numOfProposal++;
        //  return the current proposal
        return numOfProposal - 1;
    }

    /// @dev voteOnProposal allows a CryptoDevsNFT holder to cast their vote on an active proposal
    /// @param proposalIndex - the index of the proposal to vote on in the proposals array
    /// @param vote - the type of vote they want to cast
    function voteOnProposal(uint256 proposalIndex, Vote vote)
        external
        onlyNftHolder
        onlyActiveProposal(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        uint256 voterNFTBalance = cryptoDevs.balanceOf(msg.sender);
        uint256 numVotes = 0;

        // Calculate how many NFTs are owned by the voter
        // that haven't already been used for voting on this proposal

        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevs.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.Yes) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    /// @dev executeProposal allows any CryptoDevsNFT holder to execute a proposal after it's deadline has been exceeded
    /// @param proposalIndex - the index of the proposal to execute in the proposals array
    function executeProposal(uint256 proposalIndex)
        external
        onlyNftHolder
        inactiveProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        // If the proposal has more YAY votes than NAY votes
        // purchase the NFT from the FakeNFTMarketplace
        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = fakeNftMarket.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            fakeNftMarket.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    // allow only the deployer to withdraw ETH
    function withdrawEther() external onlyContractOwner {
        payable(owner).transfer(address(this).balance);
    }

    //The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}
}
