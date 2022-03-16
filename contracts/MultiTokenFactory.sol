//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiTokenFactory is ERC1155, Ownable {
    uint256 public Soldiers = 1;
    uint256 public Liutenants = 2;
    uint256 public Commanders = 3;
    uint256 public numOfTokens = 3;
    uint256 public numOfStats;
    bool paused;

    struct Stats {
        uint256 power;
        bool exists;
    }

    mapping(uint256 => Stats) public tokenStats;

    constructor() ERC1155("") {
        _mint(msg.sender, Soldiers, 100000 * 10**18, "");
        _mint(msg.sender, Liutenants, 10000 * 10**18, "");
        _mint(msg.sender, Commanders, 1000 * 10**18, "");
    }

    function setTokenURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
    }

    function createToken(uint256 _amount) public onlyOwner {
        numOfTokens += 1;
        _mint(msg.sender, numOfTokens, _amount, "");
    }

    function createStats(uint256 _tokenId, uint256 _power) public onlyOwner {
        require(!tokenStats[_tokenId].exists);
        Stats storage stats = tokenStats[_tokenId];
        stats.power = _power;
        stats.exists = true;
    }
}
