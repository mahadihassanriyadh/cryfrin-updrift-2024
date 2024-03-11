// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNFT is ERC721 {
    /*  
        - Each NFT has a unique identifier, which is the token ID.
        - The combination of the contract address and the token ID is a unique identifier for each NFT.
        - For us, we are goin to have a token counter representing each token ID.
    */

    uint256 private s_tokenCounter;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        s_tokenCounter = 0;
    }
}
