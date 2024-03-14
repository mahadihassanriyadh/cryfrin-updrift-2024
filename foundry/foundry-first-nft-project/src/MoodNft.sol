// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MoodNft is ERC721 {
    uint256 private s_tokenCounter;
    string private s_sadSvg;
    string private s_happySvg;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _sadSvg,
        string memory _happySvg
    ) ERC721(_name, _symbol) {
        s_tokenCounter = 0;
        s_sadSvg = _sadSvg;
        s_happySvg = _happySvg;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {}
}
