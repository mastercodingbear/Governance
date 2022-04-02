pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPLv2
interface CurveInterface {
    function getRate(uint256 term) external view returns (uint256 rate);
}
