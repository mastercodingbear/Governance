pragma solidity ^0.8.0;

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./Owned.sol";
import "./OGTokenInterface.sol";

// ----------------------------------------------------------------------------
// Collect Optino Governance tokens based on POAP tokenEvents
//
// Enjoy. (c) The Optino Project 2020
//
// SPDX-License-Identifier: GPLv2
// ----------------------------------------------------------------------------
interface POAP {
    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenEvent(uint256 tokenId) external view returns (uint256);
}

contract POAPOGTokenStation is Owned {
    struct TokenEventData {
        uint256 tokensToMint;
        uint256 totalCollected;
        uint256 numberCollected;
    }

    OGTokenInterface public ogToken;
    POAP public poap;
    // tokenEvents => TokenEvent
    mapping(uint256 => TokenEventData) public tokenEventData;
    // tokenId => amount collected
    mapping(uint256 => uint256) public collected;

    // POAP @ 0x22C1f6050E56d2876009903609a2cC3fEf83B415 Mainnet,
    // 0x50C5CA3e7f5566dA3Aa64eC687D283fdBEC2A2F2 Ropsten
    // POAP Simulator @ 0xb434d03e83706D011398487f158640F0336bb348 Ropsten
    constructor(OGTokenInterface _ogToken, POAP _poap) {
        initOwned(msg.sender);
        ogToken = _ogToken;
        poap = _poap;
    }

    function addTokenEvents(
        uint256[] memory _tokenEvents,
        uint256[] memory _tokensToMint
    ) public onlyOwner {
        require(_tokenEvents.length == _tokensToMint.length);
        for (uint256 i = 0; i < _tokenEvents.length; i++) {
            uint256 tokenEvent = _tokenEvents[i];
            tokenEventData[tokenEvent].tokensToMint = _tokensToMint[i];
        }
    }

    function collect(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                msg.sender == poap.ownerOf(tokenId),
                "Not owner of POAP token"
            );
            uint256 tokenEvent = poap.tokenEvent(tokenId);
            TokenEventData storage _tokenEventData = tokenEventData[tokenEvent];
            uint256 tokensToMint = _tokenEventData.tokensToMint;
            if (tokensToMint > collected[tokenId]) {
                uint256 newTokens = tokensToMint - collected[tokenId];
                if (_tokenEventData.totalCollected == 0) {
                    _tokenEventData.numberCollected++;
                }
                _tokenEventData.totalCollected += newTokens;
                collected[tokenId] += newTokens;
                require(ogToken.mint(msg.sender, newTokens), "Mint failed");
            }
        }
    }
}
