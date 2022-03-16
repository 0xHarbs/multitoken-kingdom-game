//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./KingdomFactory.sol";

contract WarRoom is KingdomFactory {
    uint256 public numOfBattles;

    struct Battle {
        string name;
        uint256 deadline;
        address attacker;
        address defender;
        address winner;
        uint256 attackerArmy;
        uint256 defenderArmy;
        mapping(address => bool) joined;
        mapping(address => Enlist) sideJoined;
    }

    struct Army {
        uint256 Soldiers;
        uint256 Lieutenants;
        uint256 Commanders;
    }

    enum Enlist {
        Attack,
        Defend
    }

    mapping(address => bool) public activeBattle;
    mapping(uint256 => Battle) public battles;

    modifier notInBattle(uint256 _kingdomId) {
        require(!activeBattle[msg.sender]);
        address defender = KingdomFactory.kingdomOwner[_kingdomId];
        require(!activeBattle[defender]);
        _;
    }

    modifier battleActive(uint256 battleId) {
        require(block.timestamp < battles[battleId].deadline);
        _;
    }

    modifier battleInActive(uint256 battleId) {
        require(block.timestamp < battles[battleId].deadline);
        _;
    }

    constructor() {}

    function createBattle(uint256 _kingdomId) public notInBattle(_kingdomId) {
        require(KingdomFactory.ownsKingdom[msg.sender]);

        address owner = KingdomFactory.kingdomOwner[_kingdomId];
        numOfBattles += 1;
        Battle storage battle = battles[numOfBattles];
        battle.deadline = block.timestamp + 1 weeks;
        battle.attacker = msg.sender;
        battle.defender = owner;
    }

    function joinBattle(uint256 _battleId, Enlist _enlist)
        public
        battleActive(_battleId)
    {
        require(!battles[_battleId].joined[msg.sender]);

        uint256 unitPower = 0;
        for (uint256 i; i < numOfTokens; i++) {
            uint256 eligibleUnits = super.balanceOf(msg.sender, i);
            Stats storage stats = tokenStats[i];
            eligibleUnits *= stats.power;
            unitPower += eligibleUnits;
        }

        if (_enlist == Enlist.Attack) {
            battles[_battleId].joined[msg.sender] = true;
            battles[_battleId].sideJoined[msg.sender] = _enlist;
            battles[_battleId].attackerArmy += unitPower;
        } else {
            battles[_battleId].joined[msg.sender] = true;
            battles[_battleId].sideJoined[msg.sender] = _enlist;
            battles[_battleId].defenderArmy += unitPower;
        }
    }

    function abandonBattle(uint256 _battleId) public battleActive(_battleId) {
        require(battles[_battleId].joined[msg.sender]);
        Enlist sideJoined = battles[_battleId].sideJoined[msg.sender];

        uint256 unitPower = 0;
        for (uint256 i; i < numOfTokens; i++) {
            uint256 eligibleUnits = super.balanceOf(msg.sender, i);
            Stats storage stats = tokenStats[i];
            eligibleUnits *= stats.power;
            unitPower += eligibleUnits;
        }

        if (sideJoined == Enlist.Attack) {
            battles[_battleId].joined[msg.sender] = false;
            battles[_battleId].attackerArmy -= unitPower;
        } else {
            battles[_battleId].joined[msg.sender] = false;
            battles[_battleId].defenderArmy -= unitPower;
        }
    }

    function executeBattle(uint256 _battleId) public battleInactive(_battleId) {
        if (battles[_battleId].attackerArmy > battles[_battleId].defenderArmy) {
            battles[_battleId].winner = battles[_battleId].attacker;
        } else {
            battles[_battleId].winner = battles[_battleId].defender;
        }
    }
}
