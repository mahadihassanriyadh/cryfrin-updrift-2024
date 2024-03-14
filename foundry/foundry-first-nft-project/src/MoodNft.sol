// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MoodNft is ERC721 {
    uint256 private s_tokenCounter;
    string private s_sadSvgImgUri;
    string private s_happySvgImgUri;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _sadSvgImgUri,
        string memory _happySvgImgUri
    ) ERC721(_name, _symbol) {
        s_tokenCounter = 0;
        _sadSvgImgUri = _sadSvgImgUri;
        _happySvgImgUri = _happySvgImgUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {}
}
