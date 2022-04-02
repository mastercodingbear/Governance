// File: contracts/Owned.sol

pragma solidity ^0.8.0;

/// @notice Ownership
// SPDX-License-Identifier: GPLv2
contract Owned {
    bool initialised;
    address public owner;

    event OwnershipTransferred(address indexed from, address indexed to);

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function initOwned(address _owner) internal {
        require(!initialised, "Already initialised");
        owner = address(uint160(_owner));
        initialised = true;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// File: contracts/ERC20.sol

pragma solidity ^0.8.0;

/// @notice ERC20 https://eips.ethereum.org/EIPS/eip-20 with optional symbol, name and decimals
// SPDX-License-Identifier: GPLv2
interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/OGTokenInterface.sol

pragma solidity ^0.8.0;


/// @notice OGTokenInterface = ERC20 + mint + burn with optional freezable cap. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
interface OGTokenInterface is ERC20 {
    function availableToMint() external view returns (uint tokens);
    function mint(address tokenOwner, uint tokens) external returns (bool success);
    function burn(uint tokens) external returns (bool success);
    function burnFrom(address tokenOwner, uint tokens) external returns (bool success);
}

// File: contracts/POAPOGTokenStation.sol

pragma solidity ^0.8.0;

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix




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
        uint tokensToMint;
        uint totalCollected;
        uint numberCollected;
    }

    OGTokenInterface public ogToken;
    POAP public poap;
    // tokenEvents => TokenEvent
    mapping(uint => TokenEventData) public tokenEventData;
    // tokenId => amount collected
    mapping(uint => uint) public collected;

    // POAP @ 0x22C1f6050E56d2876009903609a2cC3fEf83B415 Mainnet,
    // 0x50C5CA3e7f5566dA3Aa64eC687D283fdBEC2A2F2 Ropsten
    // POAP Simulator @ 0xb434d03e83706D011398487f158640F0336bb348 Ropsten
    constructor(OGTokenInterface _ogToken, POAP _poap) {
        initOwned(msg.sender);
        ogToken = _ogToken;
        poap = _poap;
    }

    function addTokenEvents(uint[] memory _tokenEvents, uint[] memory _tokensToMint) public onlyOwner {
        require(_tokenEvents.length == _tokensToMint.length);
        for (uint i = 0; i < _tokenEvents.length; i++) {
            uint tokenEvent = _tokenEvents[i];
            tokenEventData[tokenEvent].tokensToMint = _tokensToMint[i];
        }
    }

    function collect(uint[] memory tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(msg.sender == poap.ownerOf(tokenId), "Not owner of POAP token");
            uint tokenEvent = poap.tokenEvent(tokenId);
            TokenEventData storage _tokenEventData = tokenEventData[tokenEvent];
            uint tokensToMint = _tokenEventData.tokensToMint;
            if (tokensToMint > collected[tokenId]) {
                uint newTokens = tokensToMint - collected[tokenId];
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
