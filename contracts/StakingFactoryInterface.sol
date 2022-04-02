pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./CurveInterface.sol";

/// @notice OGTokenInterface = ERC20 + mint + burn
// SPDX-License-Identifier: GPLv2
interface StakingFactoryInterface {
    function availableOGTokensToMint() external view returns (uint256 tokens);

    function mintOGTokens(address tokenOwner, uint256 tokens) external;

    function mintOGDTokens(address tokenOwner, uint256 tokens) external;

    function burnFromOGDTokens(address tokenOwner, uint256 tokens) external;

    function getStakingRewardCurve()
        external
        view
        returns (CurveInterface _stakingRewardCurve);
}
