//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MultiTokenFactory.sol";

contract KingdomFactory is MultiTokenFactory {
    uint256 public numOfKingdoms;
    uint256 public numOfChallenges;

    struct Kingdom {
        address leader;
        mapping(address => bool) members;
        uint256 totalMembers;
    }

    struct Challenge {
        address challenger;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(uint256 => Kingdom) public kingdoms;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => address) public kingdomOwner;
    mapping(address => bool) public ownsKingdom;
    mapping(address => bool) public memberOfKingdom;
    mapping(address => uint256) public cooldownTime;

    modifier notKingdomOwner() {
        require(!ownsKingdom[msg.sender], "You are a kingdom owner");
        _;
    }

    modifier notKingdomMember() {
        require(!memberOfKingdom[msg.sender], "You are a member of a kingdom");
        _;
    }

    modifier memberOfThisKingdom(uint256 kingdomId) {
        require(
            kingdoms[kingdomId].members[msg.sender],
            "Not a member of this kingdom"
        );
        _;
    }

    modifier proposalActive(uint256 challengeId) {
        require(
            block.timestamp < challenges[challengeId].deadline,
            "Deadline has passed"
        );
        _;
    }

    modifier proposalInactive(uint256 challengeId) {
        require(
            block.timestamp > challenges[challengeId].deadline,
            "Proposal still active"
        );
        _;
    }

    constructor() {}

    function createKingdom() public notKingdomOwner notKingdomMember {
        require(super.balanceOf(msg.sender, 3) > 0);
        numOfKingdoms += 1;
        Kingdom storage kingdom = kingdoms[numOfKingdoms];
        kingdom.leader = msg.sender;
        memberOfKingdom[msg.sender] = true;
        kingdom.totalMembers += 1;
    }

    function joinKingdom(uint256 _kingdomId)
        public
        notKingdomOwner
        notKingdomMember
    {
        kingdoms[_kingdomId].members[msg.sender] = true;
        memberOfKingdom[msg.sender] = true;
        kingdoms[_kingdomId].totalMembers += 1;
    }

    function createChallenge(uint256 _kingdomId)
        public
        notKingdomOwner
        memberOfThisKingdom(_kingdomId)
    {
        require(super.balanceOf(msg.sender, 3) > 0);
        require(cooldownTime[msg.sender] < block.timestamp);

        numOfChallenges += 1;
        Challenge storage challenge = challenges[numOfChallenges];
        challenge.challenger = msg.sender;
        challenge.deadline = block.timestamp + 1 weeks;
    }

    function voteOnChallenge(
        uint256 _kingdomId,
        uint256 _challengeId,
        bool _value
    ) public memberOfThisKingdom(_kingdomId) proposalActive(_challengeId) {
        require(!challenges[_challengeId].voted[msg.sender]);
        uint256 numOfVotes = 0;
        for (uint256 i; i < numOfTokens; i++) {
            uint256 eligibleVotes = super.balanceOf(msg.sender, i);
            Stats storage stats = tokenStats[i];
            eligibleVotes *= stats.power;
            numOfVotes += eligibleVotes;
        }
        require(numOfVotes > 0, "You do not have any eligiblevotes");
        if (_value) {
            challenges[_kingdomId].voted[msg.sender] = true;
            challenges[_kingdomId].yesVotes += numOfVotes;
        } else if (!_value) {
            challenges[_kingdomId].voted[msg.sender] = true;
            challenges[_kingdomId].noVotes += numOfVotes;
        }
    }

    function executeChallenge(uint256 _kingdomId, uint256 _challengeId)
        public
        memberOfThisKingdom(_kingdomId)
        proposalInactive(_challengeId)
    {
        address challenger = challenges[_challengeId].challenger;
        if (
            challenges[_challengeId].yesVotes > challenges[_challengeId].noVotes
        ) {
            kingdoms[_kingdomId].leader = challenger;
        } else {
            cooldownTime[challenger] += 8 weeks;
        }
    }
}
