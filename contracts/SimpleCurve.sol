pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./Owned.sol";
import "./CurveInterface.sol";

/// @notice Simple interpolated curve by term
// SPDX-License-Identifier: GPLv2
contract SimpleCurve is Owned, CurveInterface {
    struct Point {
        uint256 term;
        uint256 rate;
    }
    Point[] public points;
    event PointUpdated(uint256 index, uint256 term, uint256 rate);
    event PointsUpdated(uint256[] terms, uint256[] rates);

    constructor(uint256[] memory terms, uint256[] memory rates) {
        initOwned(msg.sender);
        _replacePoints(terms, rates);
    }

    function pointsLength() public view returns (uint256) {
        return points.length;
    }

    function replacePoints(uint256[] memory terms, uint256[] memory rates)
        public
        onlyOwner
    {
        _replacePoints(terms, rates);
    }

    function replacePoint(
        uint256 i,
        uint256 term,
        uint256 rate
    ) public onlyOwner {
        require(i < points.length);
        points[i] = Point(term, rate);
        if (i > 0) {
            require(points[i - 1].term < term, "Invalid term");
        }
        if (i < points.length - 1) {
            require(term < points[i + 1].term, "Invalid term");
        }
        emit PointUpdated(i, term, rate);
    }

    function _replacePoints(uint256[] memory terms, uint256[] memory rates)
        internal
    {
        require(terms.length == rates.length, "Invalid data");
        delete points;
        for (uint256 i = 0; i < terms.length; i++) {
            if (i > 0) {
                require(terms[i - 1] < terms[i], "Invalid term");
            }
            points.push(Point(terms[i], rates[i]));
        }
        emit PointsUpdated(terms, rates);
    }

    function getRate(uint256 term)
        external
        view
        override
        returns (uint256 rate)
    {
        require(points.length > 0, "Curve empty");
        if (term <= points[0].term) {
            return points[0].rate;
        } else if (term >= points[points.length - 1].term) {
            return points[points.length - 1].rate;
        } else {
            for (uint256 i = 1; i < points.length; i++) {
                if (term == points[i].term) {
                    return points[i].rate;
                } else if (term > points[i - 1].term && term < points[i].term) {
                    if (points[i].rate >= points[i - 1].rate) {
                        return
                            points[i - 1].rate +
                            ((points[i].rate - points[i - 1].rate) *
                                (term - points[i - 1].term)) /
                            (points[i].term - points[i - 1].term);
                    } else {
                        return
                            points[i - 1].rate -
                            ((points[i - 1].rate - points[i].rate) *
                                (term - points[i - 1].term)) /
                            (points[i].term - points[i - 1].term);
                    }
                }
            }
        }
    }
}
