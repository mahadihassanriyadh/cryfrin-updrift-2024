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

    /*  
        ##########################################
        ########### ⭐️⭐️⭐️ tokenURI() ############
        ##########################################
        - This function returns the URI of the token.
        - This tokenURI() is actually an endpoint, some type of API call hosted somewhere that's going to return the metadata for the NFT. And that metadata is going to be a JSON object, Which would be similar to this:
            {
                "title": "Asset Metadata",
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "Identifies the asset to which this NFT represents"
                    },
                    "description": {
                        "type": "string",
                        "description": "Describes the asset to which this NFT represents"
                    },
                    "image": {
                        "type": "string",
                        "description": "A URI pointing to a resource with mime type image/* representing the asset to which this NFT represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive."
                    }
                }
            }
        - And this is what defines what the NFT looks like.
        - So for us to create an NFT, each tokenCounter / each tokenURI is going to have a URI that points to a JSON object that looks like this. Which will define what the NFT looks like.
    */
    function mintNFT() public {}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {}
}
