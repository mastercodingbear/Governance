pragma solidity ^0.8.0;

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./ABDKMathQuad.sol";

/// @notice Interest calculation utilities
// SPDX-License-Identifier: GPLv2
contract InterestUtils {
    using ABDKMathQuad for bytes16;
    bytes16 immutable ten18 = ABDKMathQuad.fromUInt(10**18);
    bytes16 immutable days365 = ABDKMathQuad.fromUInt(365 days);

    /// @notice futureValue = presentValue x exp(rate% x termInYears)
    function futureValue(
        uint256 presentValue,
        uint256 from,
        uint256 to,
        uint256 rate
    ) internal view returns (uint256) {
        require(from <= to, "Invalid date range");
        bytes16 i = ABDKMathQuad.fromUInt(rate).div(ten18);
        bytes16 t = ABDKMathQuad.fromUInt(to - from).div(days365);
        bytes16 fv = ABDKMathQuad.fromUInt(presentValue).mul(
            ABDKMathQuad.exp(i.mul(t))
        );
        return fv.toUInt();
    }
}
