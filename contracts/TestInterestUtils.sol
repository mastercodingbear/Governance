pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./InterestUtils.sol";

// SPDX-License-Identifier: GPLv2
contract TestInterestUtils is InterestUtils {
    function futureValue_(
        uint256 amount,
        uint256 from,
        uint256 to,
        uint256 rate
    ) public view returns (uint256 _futureValue, uint256 _gasUsed) {
        uint256 gasStart = gasleft();
        _futureValue = InterestUtils.futureValue(amount, from, to, rate);
        _gasUsed = gasStart - gasleft();
    }
}
