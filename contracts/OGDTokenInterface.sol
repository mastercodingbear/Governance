pragma solidity ^0.8.0;

import "./ERC20.sol";

/// @notice OGDTokenInterface = ERC20 + mint + burn + dividend payment. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
interface OGDTokenInterface is ERC20 {
    function mint(address tokenOwner, uint256 tokens)
        external
        returns (bool success);

    function burn(uint256 tokens) external returns (bool success);

    function burnFrom(address tokenOwner, uint256 tokens)
        external
        returns (bool success);
}
