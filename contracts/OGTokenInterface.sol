pragma solidity ^0.8.0;

import "./ERC20.sol";

/// @notice OGTokenInterface = ERC20 + mint + burn with optional freezable cap. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
interface OGTokenInterface is ERC20 {
    function availableToMint() external view returns (uint256 tokens);

    function mint(address tokenOwner, uint256 tokens)
        external
        returns (bool success);

    function burn(uint256 tokens) external returns (bool success);

    function burnFrom(address tokenOwner, uint256 tokens)
        external
        returns (bool success);
}
