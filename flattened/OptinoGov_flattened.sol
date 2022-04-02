// File: contracts/ERC20.sol

pragma solidity ^0.8.0;

/// @notice ERC20 https://eips.ethereum.org/EIPS/eip-20 with optional symbol, name and decimals
// SPDX-License-Identifier: GPLv2
interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// File: contracts/OGTokenInterface.sol

pragma solidity ^0.8.0;

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

// File: contracts/OGDTokenInterface.sol

pragma solidity ^0.8.0;

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

// File: contracts/ABDKMathQuad.sol

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <mikhail.vladimirov@gmail.com>
 */
// pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;
// TODO BK CHECK pragma solidity ^0.7.0;
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
    /*
     * 0.
     */
    bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

    /*
     * -0.
     */
    bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

    /*
     * +Infinity.
     */
    bytes16 private constant POSITIVE_INFINITY =
        0x7FFF0000000000000000000000000000;

    /*
     * -Infinity.
     */
    bytes16 private constant NEGATIVE_INFINITY =
        0xFFFF0000000000000000000000000000;

    /*
     * Canonical NaN value.
     */
    bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

    /**
     * Convert signed 256-bit integer number into quadruple precision number.
     *
     * @param x signed 256-bit integer number
     * @return quadruple precision number
     */
    function fromInt(int256 x) internal pure returns (bytes16) {
        if (x == 0) return bytes16(0);
        else {
            // We rely on overflow behavior here
            uint256 result = uint256(x > 0 ? x : -x);

            uint256 msb = _msb(result);
            if (msb < 112) result <<= 112 - msb;
            else if (msb > 112) result >>= msb - 112;

            result =
                (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                ((16383 + msb) << 112);
            if (x < 0) result |= 0x80000000000000000000000000000000;

            return bytes16(uint128(result));
        }
    }

    /**
     * Convert quadruple precision number into signed 256-bit integer number
     * rounding towards zero.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 256-bit integer number
     */
    function toInt(bytes16 x) internal pure returns (int256) {
        uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

        require(exponent <= 16638); // Overflow
        if (exponent < 16383) return 0; // Underflow

        uint256 result = (uint256(uint128(x)) &
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | 0x10000000000000000000000000000;

        if (exponent < 16495) result >>= 16495 - exponent;
        else if (exponent > 16495) result <<= exponent - 16495;

        if (uint128(x) >= 0x80000000000000000000000000000000) {
            // Negative
            require(
                result <=
                    0x8000000000000000000000000000000000000000000000000000000000000000
            );
            return -int256(result); // We rely on overflow behavior here
        } else {
            require(
                result <=
                    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            );
            return int256(result);
        }
    }

    /**
     * Convert unsigned 256-bit integer number into quadruple precision number.
     *
     * @param x unsigned 256-bit integer number
     * @return quadruple precision number
     */
    function fromUInt(uint256 x) internal pure returns (bytes16) {
        if (x == 0) return bytes16(0);
        else {
            uint256 result = x;

            uint256 msb = _msb(result);
            if (msb < 112) result <<= 112 - msb;
            else if (msb > 112) result >>= msb - 112;

            result =
                (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                ((16383 + msb) << 112);

            return bytes16(uint128(result));
        }
    }

    /**
     * Convert quadruple precision number into unsigned 256-bit integer number
     * rounding towards zero.  Revert on underflow.  Note, that negative floating
     * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
     * without error, because they are rounded to zero.
     *
     * @param x quadruple precision number
     * @return unsigned 256-bit integer number
     */
    function toUInt(bytes16 x) internal pure returns (uint256) {
        uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

        if (exponent < 16383) return 0; // Underflow

        require(uint128(x) < 0x80000000000000000000000000000000); // Negative

        require(exponent <= 16638); // Overflow
        uint256 result = (uint256(uint128(x)) &
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | 0x10000000000000000000000000000;

        if (exponent < 16495) result >>= 16495 - exponent;
        else if (exponent > 16495) result <<= exponent - 16495;

        return result;
    }

    /**
     * Convert signed 128.128 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 128.128 bit fixed point number
     * @return quadruple precision number
     */
    function from128x128(int256 x) internal pure returns (bytes16) {
        if (x == 0) return bytes16(0);
        else {
            // We rely on overflow behavior here
            uint256 result = uint256(x > 0 ? x : -x);

            uint256 msb = _msb(result);
            if (msb < 112) result <<= 112 - msb;
            else if (msb > 112) result >>= msb - 112;

            result =
                (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                ((16255 + msb) << 112);
            if (x < 0) result |= 0x80000000000000000000000000000000;

            return bytes16(uint128(result));
        }
    }

    /**
     * Convert quadruple precision number into signed 128.128 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 128.128 bit fixed point number
     */
    function to128x128(bytes16 x) internal pure returns (int256) {
        uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

        require(exponent <= 16510); // Overflow
        if (exponent < 16255) return 0; // Underflow

        uint256 result = (uint256(uint128(x)) &
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) | 0x10000000000000000000000000000;

        if (exponent < 16367) result >>= 16367 - exponent;
        else if (exponent > 16367) result <<= exponent - 16367;

        if (uint128(x) >= 0x80000000000000000000000000000000) {
            // Negative
            require(
                result <=
                    0x8000000000000000000000000000000000000000000000000000000000000000
            );
            return -int256(result); // We rely on overflow behavior here
        } else {
            require(
                result <=
                    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            );
            return int256(result);
        }
    }

    /**
     * Convert signed 64.64 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 64.64 bit fixed point number
     * @return quadruple precision number
     */
    function from64x64(int128 x) internal pure returns (bytes16) {
        if (x == 0) return bytes16(0);
        else {
            // We rely on overflow behavior here
            uint256 result = uint128(x > 0 ? x : -x);

            uint256 msb = _msb(result);
            if (msb < 112) result <<= 112 - msb;
            else if (msb > 112) result >>= msb - 112;

            result =
                (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
                ((16319 + msb) << 112);
            if (x < 0) result |= 0x80000000000000000000000000000000;

            return bytes16(uint128(result));
        }
    }

    /**
     * Convert quadruple precision number into signed 64.64 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 64.64 bit fixed point number
     */
    // TODO BK
    /*
  function to64x64 (bytes16 x) internal pure returns (int128) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    require (exponent <= 16446); // Overflow
    if (exponent < 16319) return 0; // Underflow

    uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
      0x10000000000000000000000000000;

    if (exponent < 16431) result >>= 16431 - exponent;
    else if (exponent > 16431) result <<= exponent - 16431;

    if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
      require (result <= 0x80000000000000000000000000000000);
      return -int128 (result); // We rely on overflow behavior here
    } else {
      require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (result);
    }
  }
  */

    /**
     * Convert octuple precision number into quadruple precision number.
     *
     * @param x octuple precision number
     * @return quadruple precision number
     */
    function fromOctuple(bytes32 x) internal pure returns (bytes16) {
        bool negative = x &
            0x8000000000000000000000000000000000000000000000000000000000000000 >
            0;

        uint256 exponent = (uint256(x) >> 236) & 0x7FFFF;
        uint256 significand = uint256(x) &
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        if (exponent == 0x7FFFF) {
            if (significand > 0) return NaN;
            else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
        }

        if (exponent > 278526)
            return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
        else if (exponent < 245649)
            return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
        else if (exponent < 245761) {
            significand =
                (significand |
                    0x100000000000000000000000000000000000000000000000000000000000) >>
                (245885 - exponent);
            exponent = 0;
        } else {
            significand >>= 124;
            exponent -= 245760;
        }

        uint128 result = uint128(significand | (exponent << 112));
        if (negative) result |= 0x80000000000000000000000000000000;

        return bytes16(result);
    }

    /**
     * Convert quadruple precision number into octuple precision number.
     *
     * @param x quadruple precision number
     * @return octuple precision number
     */
    function toOctuple(bytes16 x) internal pure returns (bytes32) {
        uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

        uint256 result = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        if (exponent == 0x7FFF)
            exponent = 0x7FFFF; // Infinity or NaN
        else if (exponent == 0) {
            if (result > 0) {
                uint256 msb = _msb(result);
                result =
                    (result << (236 - msb)) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                exponent = 245649 + msb;
            }
        } else {
            result <<= 124;
            exponent += 245760;
        }

        result |= exponent << 236;
        if (uint128(x) >= 0x80000000000000000000000000000000)
            result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

        return bytes32(result);
    }

    /**
     * Convert double precision number into quadruple precision number.
     *
     * @param x double precision number
     * @return quadruple precision number
     */
    function fromDouble(bytes8 x) internal pure returns (bytes16) {
        uint256 exponent = (uint64(x) >> 52) & 0x7FF;

        uint256 result = uint64(x) & 0xFFFFFFFFFFFFF;

        if (exponent == 0x7FF)
            exponent = 0x7FFF; // Infinity or NaN
        else if (exponent == 0) {
            if (result > 0) {
                uint256 msb = _msb(result);
                result =
                    (result << (112 - msb)) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                exponent = 15309 + msb;
            }
        } else {
            result <<= 60;
            exponent += 15360;
        }

        result |= exponent << 112;
        if (x & 0x8000000000000000 > 0)
            result |= 0x80000000000000000000000000000000;

        return bytes16(uint128(result));
    }

    /**
     * Convert quadruple precision number into double precision number.
     *
     * @param x quadruple precision number
     * @return double precision number
     */
    function toDouble(bytes16 x) internal pure returns (bytes8) {
        bool negative = uint128(x) >= 0x80000000000000000000000000000000;

        uint256 exponent = (uint128(x) >> 112) & 0x7FFF;
        uint256 significand = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        if (exponent == 0x7FFF) {
            if (significand > 0) return 0x7FF8000000000000;
            // NaN
            else
                return
                    negative
                        ? bytes8(0xFFF0000000000000) // -Infinity
                        : bytes8(0x7FF0000000000000); // Infinity
        }

        if (exponent > 17406)
            return
                negative
                    ? bytes8(0xFFF0000000000000) // -Infinity
                    : bytes8(0x7FF0000000000000);
        // Infinity
        else if (exponent < 15309)
            return
                negative
                    ? bytes8(0x8000000000000000) // -0
                    : bytes8(0x0000000000000000);
        // 0
        else if (exponent < 15361) {
            significand =
                (significand | 0x10000000000000000000000000000) >>
                (15421 - exponent);
            exponent = 0;
        } else {
            significand >>= 60;
            exponent -= 15360;
        }

        uint64 result = uint64(significand | (exponent << 52));
        if (negative) result |= 0x8000000000000000;

        return bytes8(result);
    }

    /**
     * Test whether given quadruple precision number is NaN.
     *
     * @param x quadruple precision number
     * @return true if x is NaN, false otherwise
     */
    function isNaN(bytes16 x) internal pure returns (bool) {
        return
            uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
            0x7FFF0000000000000000000000000000;
    }

    /**
     * Test whether given quadruple precision number is positive or negative
     * infinity.
     *
     * @param x quadruple precision number
     * @return true if x is positive or negative infinity, false otherwise
     */
    function isInfinity(bytes16 x) internal pure returns (bool) {
        return
            uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
            0x7FFF0000000000000000000000000000;
    }

    /**
     * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
     * is positive.  Note that sign (-0) is zero.  Revert if x is NaN.
     *
     * @param x quadruple precision number
     * @return sign of x
     */
    function sign(bytes16 x) internal pure returns (int8) {
        uint128 absoluteX = uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        require(absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

        if (absoluteX == 0) return 0;
        else if (uint128(x) >= 0x80000000000000000000000000000000) return -1;
        else return 1;
    }

    /**
     * Calculate sign (x - y).  Revert if either argument is NaN, or both
     * arguments are infinities of the same sign.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return sign (x - y)
     */
    function cmp(bytes16 x, bytes16 y) internal pure returns (int8) {
        uint128 absoluteX = uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        require(absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

        uint128 absoluteY = uint128(y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        require(absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

        // Not infinities of the same sign
        require(x != y || absoluteX < 0x7FFF0000000000000000000000000000);

        if (x == y) return 0;
        else {
            bool negativeX = uint128(x) >= 0x80000000000000000000000000000000;
            bool negativeY = uint128(y) >= 0x80000000000000000000000000000000;

            if (negativeX) {
                if (negativeY) return absoluteX > absoluteY ? -1 : int8(1);
                else return -1;
            } else {
                if (negativeY) return 1;
                else return absoluteX > absoluteY ? int8(1) : -1;
            }
        }
    }

    /**
     * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
     * anything.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return true if x equals to y, false otherwise
     */
    function eq(bytes16 x, bytes16 y) internal pure returns (bool) {
        if (x == y) {
            return
                uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
                0x7FFF0000000000000000000000000000;
        } else return false;
    }

    /**
     * Calculate x + y.  Special values behave in the following way:
     *
     * NaN + x = NaN for any x.
     * Infinity + x = Infinity for any finite x.
     * -Infinity + x = -Infinity for any finite x.
     * Infinity + Infinity = Infinity.
     * -Infinity + -Infinity = -Infinity.
     * Infinity + -Infinity = -Infinity + Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function add(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
        uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

        if (xExponent == 0x7FFF) {
            if (yExponent == 0x7FFF) {
                if (x == y) return x;
                else return NaN;
            } else return x;
        } else if (yExponent == 0x7FFF) return y;
        else {
            bool xSign = uint128(x) >= 0x80000000000000000000000000000000;
            uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (xExponent == 0) xExponent = 1;
            else xSignifier |= 0x10000000000000000000000000000;

            bool ySign = uint128(y) >= 0x80000000000000000000000000000000;
            uint256 ySignifier = uint128(y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (yExponent == 0) yExponent = 1;
            else ySignifier |= 0x10000000000000000000000000000;

            if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
            else if (ySignifier == 0)
                return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
            else {
                int256 delta = int256(xExponent) - int256(yExponent);

                if (xSign == ySign) {
                    if (delta > 112) return x;
                    else if (delta > 0) ySignifier >>= uint256(delta);
                    else if (delta < -112) return y;
                    else if (delta < 0) {
                        xSignifier >>= uint256(-delta);
                        xExponent = yExponent;
                    }

                    xSignifier += ySignifier;

                    if (xSignifier >= 0x20000000000000000000000000000) {
                        xSignifier >>= 1;
                        xExponent += 1;
                    }

                    if (xExponent == 0x7FFF)
                        return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
                    else {
                        if (xSignifier < 0x10000000000000000000000000000)
                            xExponent = 0;
                        else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                        return
                            bytes16(
                                uint128(
                                    (
                                        xSign
                                            ? 0x80000000000000000000000000000000
                                            : 0
                                    ) |
                                        (xExponent << 112) |
                                        xSignifier
                                )
                            );
                    }
                } else {
                    if (delta > 0) {
                        xSignifier <<= 1;
                        xExponent -= 1;
                    } else if (delta < 0) {
                        ySignifier <<= 1;
                        xExponent = yExponent - 1;
                    }

                    if (delta > 112) ySignifier = 1;
                    else if (delta > 1)
                        ySignifier =
                            ((ySignifier - 1) >> uint256(delta - 1)) +
                            1;
                    else if (delta < -112) xSignifier = 1;
                    else if (delta < -1)
                        xSignifier =
                            ((xSignifier - 1) >> uint256(-delta - 1)) +
                            1;

                    if (xSignifier >= ySignifier) xSignifier -= ySignifier;
                    else {
                        xSignifier = ySignifier - xSignifier;
                        xSign = ySign;
                    }

                    if (xSignifier == 0) return POSITIVE_ZERO;

                    uint256 msb = _msb(xSignifier);

                    if (msb == 113) {
                        xSignifier =
                            (xSignifier >> 1) &
                            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                        xExponent += 1;
                    } else if (msb < 112) {
                        uint256 shift = 112 - msb;
                        if (xExponent > shift) {
                            xSignifier =
                                (xSignifier << shift) &
                                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                            xExponent -= shift;
                        } else {
                            xSignifier <<= xExponent - 1;
                            xExponent = 0;
                        }
                    } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                    if (xExponent == 0x7FFF)
                        return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
                    else
                        return
                            bytes16(
                                uint128(
                                    (
                                        xSign
                                            ? 0x80000000000000000000000000000000
                                            : 0
                                    ) |
                                        (xExponent << 112) |
                                        xSignifier
                                )
                            );
                }
            }
        }
    }

    /**
     * Calculate x - y.  Special values behave in the following way:
     *
     * NaN - x = NaN for any x.
     * Infinity - x = Infinity for any finite x.
     * -Infinity - x = -Infinity for any finite x.
     * Infinity - -Infinity = Infinity.
     * -Infinity - Infinity = -Infinity.
     * Infinity - Infinity = -Infinity - -Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function sub(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        return add(x, y ^ 0x80000000000000000000000000000000);
    }

    /**
     * Calculate x * y.  Special values behave in the following way:
     *
     * NaN * x = NaN for any x.
     * Infinity * x = Infinity for any finite positive x.
     * Infinity * x = -Infinity for any finite negative x.
     * -Infinity * x = -Infinity for any finite positive x.
     * -Infinity * x = Infinity for any finite negative x.
     * Infinity * 0 = NaN.
     * -Infinity * 0 = NaN.
     * Infinity * Infinity = Infinity.
     * Infinity * -Infinity = -Infinity.
     * -Infinity * Infinity = -Infinity.
     * -Infinity * -Infinity = Infinity.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function mul(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
        uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

        if (xExponent == 0x7FFF) {
            if (yExponent == 0x7FFF) {
                if (x == y) return x ^ (y & 0x80000000000000000000000000000000);
                else if (x ^ y == 0x80000000000000000000000000000000)
                    return x | y;
                else return NaN;
            } else {
                if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
                else return x ^ (y & 0x80000000000000000000000000000000);
            }
        } else if (yExponent == 0x7FFF) {
            if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
            else return y ^ (x & 0x80000000000000000000000000000000);
        } else {
            uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (xExponent == 0) xExponent = 1;
            else xSignifier |= 0x10000000000000000000000000000;

            uint256 ySignifier = uint128(y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (yExponent == 0) yExponent = 1;
            else ySignifier |= 0x10000000000000000000000000000;

            xSignifier *= ySignifier;
            if (xSignifier == 0)
                return
                    (x ^ y) & 0x80000000000000000000000000000000 > 0
                        ? NEGATIVE_ZERO
                        : POSITIVE_ZERO;

            xExponent += yExponent;

            uint256 msb = xSignifier >=
                0x200000000000000000000000000000000000000000000000000000000
                ? 225
                : xSignifier >=
                    0x100000000000000000000000000000000000000000000000000000000
                ? 224
                : _msb(xSignifier);

            if (xExponent + msb < 16496) {
                // Underflow
                xExponent = 0;
                xSignifier = 0;
            } else if (xExponent + msb < 16608) {
                // Subnormal
                if (xExponent < 16496) xSignifier >>= 16496 - xExponent;
                else if (xExponent > 16496) xSignifier <<= xExponent - 16496;
                xExponent = 0;
            } else if (xExponent + msb > 49373) {
                xExponent = 0x7FFF;
                xSignifier = 0;
            } else {
                if (msb > 112) xSignifier >>= msb - 112;
                else if (msb < 112) xSignifier <<= 112 - msb;

                xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                xExponent = xExponent + msb - 16607;
            }

            return
                bytes16(
                    uint128(
                        uint128((x ^ y) & 0x80000000000000000000000000000000) |
                            (xExponent << 112) |
                            xSignifier
                    )
                );
        }
    }

    /**
     * Calculate x / y.  Special values behave in the following way:
     *
     * NaN / x = NaN for any x.
     * x / NaN = NaN for any x.
     * Infinity / x = Infinity for any finite non-negative x.
     * Infinity / x = -Infinity for any finite negative x including -0.
     * -Infinity / x = -Infinity for any finite non-negative x.
     * -Infinity / x = Infinity for any finite negative x including -0.
     * x / Infinity = 0 for any finite non-negative x.
     * x / -Infinity = -0 for any finite non-negative x.
     * x / Infinity = -0 for any finite non-negative x including -0.
     * x / -Infinity = 0 for any finite non-negative x including -0.
     *
     * Infinity / Infinity = NaN.
     * Infinity / -Infinity = -NaN.
     * -Infinity / Infinity = -NaN.
     * -Infinity / -Infinity = NaN.
     *
     * Division by zero behaves in the following way:
     *
     * x / 0 = Infinity for any finite positive x.
     * x / -0 = -Infinity for any finite positive x.
     * x / 0 = -Infinity for any finite negative x.
     * x / -0 = Infinity for any finite negative x.
     * 0 / 0 = NaN.
     * 0 / -0 = NaN.
     * -0 / 0 = NaN.
     * -0 / -0 = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function div(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
        uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

        if (xExponent == 0x7FFF) {
            if (yExponent == 0x7FFF) return NaN;
            else return x ^ (y & 0x80000000000000000000000000000000);
        } else if (yExponent == 0x7FFF) {
            if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
            else
                return
                    POSITIVE_ZERO |
                    ((x ^ y) & 0x80000000000000000000000000000000);
        } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
            if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
            else
                return
                    POSITIVE_INFINITY |
                    ((x ^ y) & 0x80000000000000000000000000000000);
        } else {
            uint256 ySignifier = uint128(y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (yExponent == 0) yExponent = 1;
            else ySignifier |= 0x10000000000000000000000000000;

            uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (xExponent == 0) {
                if (xSignifier != 0) {
                    uint256 shift = 226 - _msb(xSignifier);

                    xSignifier <<= shift;

                    xExponent = 1;
                    yExponent += shift - 114;
                }
            } else {
                xSignifier =
                    (xSignifier | 0x10000000000000000000000000000) <<
                    114;
            }

            xSignifier = xSignifier / ySignifier;
            if (xSignifier == 0)
                return
                    (x ^ y) & 0x80000000000000000000000000000000 > 0
                        ? NEGATIVE_ZERO
                        : POSITIVE_ZERO;

            assert(xSignifier >= 0x1000000000000000000000000000);

            uint256 msb = xSignifier >= 0x80000000000000000000000000000
                ? _msb(xSignifier)
                : xSignifier >= 0x40000000000000000000000000000
                ? 114
                : xSignifier >= 0x20000000000000000000000000000
                ? 113
                : 112;

            if (xExponent + msb > yExponent + 16497) {
                // Overflow
                xExponent = 0x7FFF;
                xSignifier = 0;
            } else if (xExponent + msb + 16380 < yExponent) {
                // Underflow
                xExponent = 0;
                xSignifier = 0;
            } else if (xExponent + msb + 16268 < yExponent) {
                // Subnormal
                if (xExponent + 16380 > yExponent)
                    xSignifier <<= xExponent + 16380 - yExponent;
                else if (xExponent + 16380 < yExponent)
                    xSignifier >>= yExponent - xExponent - 16380;

                xExponent = 0;
            } else {
                // Normal
                if (msb > 112) xSignifier >>= msb - 112;

                xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                xExponent = xExponent + msb + 16269 - yExponent;
            }

            return
                bytes16(
                    uint128(
                        uint128((x ^ y) & 0x80000000000000000000000000000000) |
                            (xExponent << 112) |
                            xSignifier
                    )
                );
        }
    }

    /**
     * Calculate -x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function neg(bytes16 x) internal pure returns (bytes16) {
        return x ^ 0x80000000000000000000000000000000;
    }

    /**
     * Calculate |x|.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function abs(bytes16 x) internal pure returns (bytes16) {
        return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    /**
     * Calculate square root of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function sqrt(bytes16 x) internal pure returns (bytes16) {
        if (uint128(x) > 0x80000000000000000000000000000000) return NaN;
        else {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            if (xExponent == 0x7FFF) return x;
            else {
                uint256 xSignifier = uint128(x) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                if (xSignifier == 0) return POSITIVE_ZERO;

                bool oddExponent = xExponent & 0x1 == 0;
                xExponent = (xExponent + 16383) >> 1;

                if (oddExponent) {
                    if (xSignifier >= 0x10000000000000000000000000000)
                        xSignifier <<= 113;
                    else {
                        uint256 msb = _msb(xSignifier);
                        uint256 shift = (226 - msb) & 0xFE;
                        xSignifier <<= shift;
                        xExponent -= (shift - 112) >> 1;
                    }
                } else {
                    if (xSignifier >= 0x10000000000000000000000000000)
                        xSignifier <<= 112;
                    else {
                        uint256 msb = _msb(xSignifier);
                        uint256 shift = (225 - msb) & 0xFE;
                        xSignifier <<= shift;
                        xExponent -= (shift - 112) >> 1;
                    }
                }

                uint256 r = 0x10000000000000000000000000000;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
                uint256 r1 = xSignifier / r;
                if (r1 < r) r = r1;

                return
                    bytes16(
                        uint128(
                            (xExponent << 112) |
                                (r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                        )
                    );
            }
        }
    }

    /**
     * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function log_2(bytes16 x) internal pure returns (bytes16) {
        if (uint128(x) > 0x80000000000000000000000000000000) return NaN;
        else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO;
        else {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            if (xExponent == 0x7FFF) return x;
            else {
                uint256 xSignifier = uint128(x) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                if (xSignifier == 0) return NEGATIVE_INFINITY;

                bool resultNegative;
                uint256 resultExponent = 16495;
                uint256 resultSignifier;

                if (xExponent >= 0x3FFF) {
                    resultNegative = false;
                    resultSignifier = xExponent - 0x3FFF;
                    xSignifier <<= 15;
                } else {
                    resultNegative = true;
                    if (xSignifier >= 0x10000000000000000000000000000) {
                        resultSignifier = 0x3FFE - xExponent;
                        xSignifier <<= 15;
                    } else {
                        uint256 msb = _msb(xSignifier);
                        resultSignifier = 16493 - msb;
                        xSignifier <<= 127 - msb;
                    }
                }

                if (xSignifier == 0x80000000000000000000000000000000) {
                    if (resultNegative) resultSignifier += 1;
                    uint256 shift = 112 - _msb(resultSignifier);
                    resultSignifier <<= shift;
                    resultExponent -= shift;
                } else {
                    uint256 bb = resultNegative ? 1 : 0;
                    while (resultSignifier < 0x10000000000000000000000000000) {
                        resultSignifier <<= 1;
                        resultExponent -= 1;

                        xSignifier *= xSignifier;
                        uint256 b = xSignifier >> 255;
                        resultSignifier += b ^ bb;
                        xSignifier >>= 127 + b;
                    }
                }

                return
                    bytes16(
                        uint128(
                            (
                                resultNegative
                                    ? 0x80000000000000000000000000000000
                                    : 0
                            ) |
                                (resultExponent << 112) |
                                (resultSignifier &
                                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                        )
                    );
            }
        }
    }

    /**
     * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function ln(bytes16 x) internal pure returns (bytes16) {
        return mul(log_2(x), 0x3FFE62E42FEFA39EF35793C7673007E5);
    }

    /**
     * Calculate 2^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function pow_2(bytes16 x) internal pure returns (bytes16) {
        bool xNegative = uint128(x) > 0x80000000000000000000000000000000;
        uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
        uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
        else if (xExponent > 16397)
            return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
        else if (xExponent < 16255) return 0x3FFF0000000000000000000000000000;
        else {
            if (xExponent == 0) xExponent = 1;
            else xSignifier |= 0x10000000000000000000000000000;

            if (xExponent > 16367) xSignifier <<= xExponent - 16367;
            else if (xExponent < 16367) xSignifier >>= 16367 - xExponent;

            if (
                xNegative && xSignifier > 0x406E00000000000000000000000000000000
            ) return POSITIVE_ZERO;

            if (
                !xNegative &&
                xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            ) return POSITIVE_INFINITY;

            uint256 resultExponent = xSignifier >> 128;
            xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            if (xNegative && xSignifier != 0) {
                xSignifier = ~xSignifier;
                resultExponent += 1;
            }

            uint256 resultSignifier = 0x80000000000000000000000000000000;
            if (xSignifier & 0x80000000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E) >>
                    128;
            if (xSignifier & 0x40000000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >>
                    128;
            if (xSignifier & 0x20000000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >>
                    128;
            if (xSignifier & 0x10000000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10B5586CF9890F6298B92B71842A98363) >>
                    128;
            if (xSignifier & 0x8000000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD) >>
                    128;
            if (xSignifier & 0x4000000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >>
                    128;
            if (xSignifier & 0x2000000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F) >>
                    128;
            if (xSignifier & 0x1000000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >>
                    128;
            if (xSignifier & 0x800000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B) >>
                    128;
            if (xSignifier & 0x400000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F) >>
                    128;
            if (xSignifier & 0x200000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF) >>
                    128;
            if (xSignifier & 0x100000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725) >>
                    128;
            if (xSignifier & 0x80000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D) >>
                    128;
            if (xSignifier & 0x40000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3) >>
                    128;
            if (xSignifier & 0x20000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000162E525EE054754457D5995292026) >>
                    128;
            if (xSignifier & 0x10000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC) >>
                    128;
            if (xSignifier & 0x8000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >>
                    128;
            if (xSignifier & 0x4000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >>
                    128;
            if (xSignifier & 0x2000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000162E43F4F831060E02D839A9D16D) >>
                    128;
            if (xSignifier & 0x1000000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000B1721BCFC99D9F890EA06911763) >>
                    128;
            if (xSignifier & 0x800000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628) >>
                    128;
            if (xSignifier & 0x400000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B) >>
                    128;
            if (xSignifier & 0x200000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000162E430E5A18F6119E3C02282A5) >>
                    128;
            if (xSignifier & 0x100000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE) >>
                    128;
            if (xSignifier & 0x80000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF) >>
                    128;
            if (xSignifier & 0x40000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A) >>
                    128;
            if (xSignifier & 0x20000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06) >>
                    128;
            if (xSignifier & 0x10000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9) >>
                    128;
            if (xSignifier & 0x8000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >>
                    128;
            if (xSignifier & 0x4000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50) >>
                    128;
            if (xSignifier & 0x2000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF) >>
                    128;
            if (xSignifier & 0x1000000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000B17217F80F4EF5AADDA45554) >>
                    128;
            if (xSignifier & 0x800000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD) >>
                    128;
            if (xSignifier & 0x400000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC) >>
                    128;
            if (xSignifier & 0x200000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000162E42FEFB2FED257559BDAA) >>
                    128;
            if (xSignifier & 0x100000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE) >>
                    128;
            if (xSignifier & 0x80000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE) >>
                    128;
            if (xSignifier & 0x40000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D) >>
                    128;
            if (xSignifier & 0x20000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000162E42FEFA494F1478FDE05) >>
                    128;
            if (xSignifier & 0x10000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000B17217F7D20CF927C8E94C) >>
                    128;
            if (xSignifier & 0x8000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D) >>
                    128;
            if (xSignifier & 0x4000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000002C5C85FDF477B662B26945) >>
                    128;
            if (xSignifier & 0x2000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000162E42FEFA3AE53369388C) >>
                    128;
            if (xSignifier & 0x1000000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000B17217F7D1D351A389D40) >>
                    128;
            if (xSignifier & 0x800000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE) >>
                    128;
            if (xSignifier & 0x400000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E) >>
                    128;
            if (xSignifier & 0x200000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000162E42FEFA39FE95583C2) >>
                    128;
            if (xSignifier & 0x100000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1) >>
                    128;
            if (xSignifier & 0x80000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0) >>
                    128;
            if (xSignifier & 0x40000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000002C5C85FDF473E242EA38) >>
                    128;
            if (xSignifier & 0x20000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000162E42FEFA39F02B772C) >>
                    128;
            if (xSignifier & 0x10000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A) >>
                    128;
            if (xSignifier & 0x8000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E) >>
                    128;
            if (xSignifier & 0x4000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000002C5C85FDF473DEA871F) >>
                    128;
            if (xSignifier & 0x2000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000162E42FEFA39EF44D91) >>
                    128;
            if (xSignifier & 0x1000000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000B17217F7D1CF79E949) >>
                    128;
            if (xSignifier & 0x800000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000058B90BFBE8E7BCE544) >>
                    128;
            if (xSignifier & 0x400000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA) >>
                    128;
            if (xSignifier & 0x200000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000162E42FEFA39EF366F) >>
                    128;
            if (xSignifier & 0x100000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000B17217F7D1CF79AFA) >>
                    128;
            if (xSignifier & 0x80000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D) >>
                    128;
            if (xSignifier & 0x40000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000002C5C85FDF473DE6B2) >>
                    128;
            if (xSignifier & 0x20000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000162E42FEFA39EF358) >>
                    128;
            if (xSignifier & 0x10000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000B17217F7D1CF79AB) >>
                    128;
            if (xSignifier & 0x8000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5) >>
                    128;
            if (xSignifier & 0x4000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000002C5C85FDF473DE6A) >>
                    128;
            if (xSignifier & 0x2000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000162E42FEFA39EF34) >>
                    128;
            if (xSignifier & 0x1000000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000B17217F7D1CF799) >>
                    128;
            if (xSignifier & 0x800000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000058B90BFBE8E7BCC) >>
                    128;
            if (xSignifier & 0x400000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000002C5C85FDF473DE5) >>
                    128;
            if (xSignifier & 0x200000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000162E42FEFA39EF2) >>
                    128;
            if (xSignifier & 0x100000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000B17217F7D1CF78) >>
                    128;
            if (xSignifier & 0x80000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000058B90BFBE8E7BB) >>
                    128;
            if (xSignifier & 0x40000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000002C5C85FDF473DD) >>
                    128;
            if (xSignifier & 0x20000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000162E42FEFA39EE) >>
                    128;
            if (xSignifier & 0x10000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000B17217F7D1CF6) >>
                    128;
            if (xSignifier & 0x8000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000058B90BFBE8E7A) >>
                    128;
            if (xSignifier & 0x4000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000002C5C85FDF473C) >>
                    128;
            if (xSignifier & 0x2000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000162E42FEFA39D) >>
                    128;
            if (xSignifier & 0x1000000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000B17217F7D1CE) >>
                    128;
            if (xSignifier & 0x800000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000058B90BFBE8E6) >>
                    128;
            if (xSignifier & 0x400000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000002C5C85FDF472) >>
                    128;
            if (xSignifier & 0x200000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000162E42FEFA38) >>
                    128;
            if (xSignifier & 0x100000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000B17217F7D1B) >>
                    128;
            if (xSignifier & 0x80000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000058B90BFBE8D) >>
                    128;
            if (xSignifier & 0x40000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000002C5C85FDF46) >>
                    128;
            if (xSignifier & 0x20000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000162E42FEFA2) >>
                    128;
            if (xSignifier & 0x10000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000B17217F7D0) >>
                    128;
            if (xSignifier & 0x8000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000058B90BFBE7) >>
                    128;
            if (xSignifier & 0x4000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000002C5C85FDF3) >>
                    128;
            if (xSignifier & 0x2000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000162E42FEF9) >>
                    128;
            if (xSignifier & 0x1000000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000B17217F7C) >>
                    128;
            if (xSignifier & 0x800000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000058B90BFBD) >>
                    128;
            if (xSignifier & 0x400000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000002C5C85FDE) >>
                    128;
            if (xSignifier & 0x200000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000162E42FEE) >>
                    128;
            if (xSignifier & 0x100000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000000B17217F6) >>
                    128;
            if (xSignifier & 0x80000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000058B90BFA) >>
                    128;
            if (xSignifier & 0x40000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000002C5C85FC) >>
                    128;
            if (xSignifier & 0x20000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000000162E42FD) >>
                    128;
            if (xSignifier & 0x10000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000000B17217E) >>
                    128;
            if (xSignifier & 0x8000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000000058B90BE) >>
                    128;
            if (xSignifier & 0x4000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000002C5C85E) >>
                    128;
            if (xSignifier & 0x2000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000000162E42E) >>
                    128;
            if (xSignifier & 0x1000000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000000B17216) >>
                    128;
            if (xSignifier & 0x800000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000000058B90A) >>
                    128;
            if (xSignifier & 0x400000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000000002C5C84) >>
                    128;
            if (xSignifier & 0x200000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000000162E41) >>
                    128;
            if (xSignifier & 0x100000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000000000B1720) >>
                    128;
            if (xSignifier & 0x80000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000000058B8F) >>
                    128;
            if (xSignifier & 0x40000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000000002C5C7) >>
                    128;
            if (xSignifier & 0x20000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000000000162E3) >>
                    128;
            if (xSignifier & 0x10000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000000000B171) >>
                    128;
            if (xSignifier & 0x8000 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000000000058B8) >>
                    128;
            if (xSignifier & 0x4000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000000002C5B) >>
                    128;
            if (xSignifier & 0x2000 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000000000162D) >>
                    128;
            if (xSignifier & 0x1000 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000000000B16) >>
                    128;
            if (xSignifier & 0x800 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000000000058A) >>
                    128;
            if (xSignifier & 0x400 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000000000002C4) >>
                    128;
            if (xSignifier & 0x200 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000000000161) >>
                    128;
            if (xSignifier & 0x100 > 0)
                resultSignifier =
                    (resultSignifier * 0x1000000000000000000000000000000B0) >>
                    128;
            if (xSignifier & 0x80 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000000000057) >>
                    128;
            if (xSignifier & 0x40 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000000000002B) >>
                    128;
            if (xSignifier & 0x20 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000000000015) >>
                    128;
            if (xSignifier & 0x10 > 0)
                resultSignifier =
                    (resultSignifier * 0x10000000000000000000000000000000A) >>
                    128;
            if (xSignifier & 0x8 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000000000004) >>
                    128;
            if (xSignifier & 0x4 > 0)
                resultSignifier =
                    (resultSignifier * 0x100000000000000000000000000000001) >>
                    128;

            if (!xNegative) {
                resultSignifier =
                    (resultSignifier >> 15) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                resultExponent += 0x3FFF;
            } else if (resultExponent <= 0x3FFE) {
                resultSignifier =
                    (resultSignifier >> 15) &
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                resultExponent = 0x3FFF - resultExponent;
            } else {
                resultSignifier = resultSignifier >> (resultExponent - 16367);
                resultExponent = 0;
            }

            return bytes16(uint128((resultExponent << 112) | resultSignifier));
        }
    }

    /**
     * Calculate e^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function exp(bytes16 x) internal pure returns (bytes16) {
        return pow_2(mul(x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
    }

    /**
     * Get index of the most significant non-zero bit in binary representation of
     * x.  Reverts if x is zero.
     *
     * @return index of the most significant non-zero bit in binary representation
     *         of x
     */
    function _msb(uint256 x) private pure returns (uint256) {
        require(x > 0);

        uint256 result = 0;

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            result += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            result += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            result += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            result += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            result += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            result += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            result += 2;
        }
        if (x >= 0x2) result += 1; // No need to shift x anymore

        return result;
    }
}

// File: contracts/InterestUtils.sol

pragma solidity ^0.8.0;

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix

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

// File: contracts/CurveInterface.sol

pragma solidity ^0.8.0;

// SPDX-License-Identifier: GPLv2
interface CurveInterface {
    function getRate(uint256 term) external view returns (uint256 rate);
}

// File: contracts/OptinoGov.sol

pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix

/// @notice Optino Governance config
contract OptinoGovBase {
    bytes32 private constant KEY_OGTOKEN =
        keccak256(abi.encodePacked("ogToken"));
    bytes32 private constant KEY_OGDTOKEN =
        keccak256(abi.encodePacked("ogdToken"));
    bytes32 private constant KEY_OGREWARDCURVE =
        keccak256(abi.encodePacked("ogRewardCurve"));
    bytes32 private constant KEY_VOTEWEIGHTCURVE =
        keccak256(abi.encodePacked("voteWeightCurve"));
    bytes32 private constant KEY_MAXDURATION =
        keccak256(abi.encodePacked("maxDuration"));
    bytes32 private constant KEY_COLLECTREWARDFORFEE =
        keccak256(abi.encodePacked("collectRewardForFee"));
    bytes32 private constant KEY_COLLECTREWARDFORDELAY =
        keccak256(abi.encodePacked("collectRewardForDelay"));
    bytes32 private constant KEY_PROPOSALCOST =
        keccak256(abi.encodePacked("proposalCost"));
    bytes32 private constant KEY_PROPOSALTHRESHOLD =
        keccak256(abi.encodePacked("proposalThreshold"));
    bytes32 private constant KEY_VOTEREWARD =
        keccak256(abi.encodePacked("voteReward"));
    bytes32 private constant KEY_QUORUM = keccak256(abi.encodePacked("quorum"));
    bytes32 private constant KEY_QUORUMDECAYPERSECOND =
        keccak256(abi.encodePacked("quorumDecayPerSecond"));
    bytes32 private constant KEY_VOTINGDURATION =
        keccak256(abi.encodePacked("votingDuration"));
    bytes32 private constant KEY_EXECUTEDELAY =
        keccak256(abi.encodePacked("executeDelay"));

    OGTokenInterface public ogToken;
    OGDTokenInterface public ogdToken;
    CurveInterface public ogRewardCurve;
    CurveInterface public voteWeightCurve;
    uint256 public maxDuration = 10000 seconds; // Testing 365 days;
    uint256 public collectRewardForFee = 5e16; // 5%, 18 decimals
    uint256 public collectRewardForDelay = 1 seconds; // Testing 7 days
    uint256 public proposalCost = 100e18; // 100 tokens assuming 18 decimals
    uint256 public proposalThreshold = 1e15; // 0.1%, 18 decimals
    uint256 public voteReward = 1e15; // 0.1% of weightedVote
    uint256 public quorum = 2e17; // 20%, 18 decimals
    uint256 public quorumDecayPerSecond = 4e17 / uint256(365 days); // 40% per year, i.e., 0 in 6 months
    uint256 public votingDuration = 10 seconds; // 3 days;
    uint256 public executeDelay = 10 seconds; // 2 days;

    event ConfigUpdated(string key, uint256 value);

    modifier onlySelf() {
        require(msg.sender == address(this), "Not self");
        _;
    }

    constructor(
        OGTokenInterface _ogToken,
        OGDTokenInterface _ogdToken,
        CurveInterface _ogRewardCurve,
        CurveInterface _voteWeightCurve
    ) {
        ogToken = _ogToken;
        ogdToken = _ogdToken;
        ogRewardCurve = _ogRewardCurve;
        voteWeightCurve = _voteWeightCurve;
    }

    function setConfig(string memory key, uint256 value) external onlySelf {
        bytes32 _key = keccak256(abi.encodePacked(key));
        /*if (_key == KEY_OGTOKEN) {
            ogToken = OGTokenInterface(address(value));
        } else if (_key == KEY_VOTEWEIGHTCURVE) {
            ogdToken = OGDTokenInterface(address(value));
        } else*/
        if (_key == KEY_OGREWARDCURVE) {
            ogRewardCurve = CurveInterface(address(uint160(value)));
        } else if (_key == KEY_VOTEWEIGHTCURVE) {
            voteWeightCurve = CurveInterface(address(uint160(value)));
        } else if (_key == KEY_MAXDURATION) {
            require(maxDuration < 5 * 365 days); // Cannot exceed 5 years
            maxDuration = value;
        } else if (_key == KEY_COLLECTREWARDFORFEE) {
            require(collectRewardForFee < 1e18); // Cannot exceed 100%
            collectRewardForFee = value;
        } else if (_key == KEY_COLLECTREWARDFORDELAY) {
            collectRewardForDelay = value;
        } else if (_key == KEY_PROPOSALCOST) {
            proposalCost = value;
        } else if (_key == KEY_PROPOSALTHRESHOLD) {
            proposalThreshold = value;
        } else if (_key == KEY_VOTEREWARD) {
            voteReward = value;
        } else if (_key == KEY_QUORUM) {
            quorum = value;
        } else if (_key == KEY_QUORUMDECAYPERSECOND) {
            quorumDecayPerSecond = value;
        } else if (_key == KEY_VOTINGDURATION) {
            votingDuration = value;
        } else if (_key == KEY_EXECUTEDELAY) {
            executeDelay = value;
        } else {
            revert(); // Invalid key
        }
        emit ConfigUpdated(key, value);
    }

    // ------------------------------------------------------------------------
    // ecrecover from a signature rather than the signature in parts [v, r, s]
    // The signature format is a compact form {bytes32 r}{bytes32 s}{uint8 v}.
    // Compact means, uint8 is not padded to 32 bytes.
    //
    // An invalid signature results in the address(0) being returned, make
    // sure that the returned result is checked to be non-zero for validity
    //
    // Parts from https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    // ------------------------------------------------------------------------
    function ecrecoverFromSig(bytes32 hash, bytes memory sig)
        public
        pure
        returns (address recoveredAddress)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            // Here we are loading the last 32 bytes. We exploit the fact that 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))
        }
        // Albeit non-transactional signatures are not specified by the YP, one would expect it to match the YP range of [27, 28]
        // geth uses [0, 1] and some clients have followed. This might change, see https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

/// @notice Optino Governance. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
contract OptinoGov is ERC20, OptinoGovBase, InterestUtils {
    struct Account {
        uint64 duration;
        uint64 end;
        uint64 lastDelegated;
        uint64 lastVoted;
        uint64 index;
        address delegatee;
        uint256 rate;
        uint256 balance;
        uint256 votes;
        uint256 delegatedVotes;
    }
    struct Proposal {
        uint64 start;
        uint32 executed;
        address proposer;
        string description;
        address[] targets;
        uint256[] values;
        bytes[] data;
        uint256 forVotes;
        uint256 againstVotes;
    }

    string private constant NAME = "OptinoGov";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant EIP712_VOTE_TYPEHASH =
        keccak256("Vote(uint256 id,bool support)");
    bytes32 private immutable EIP712_DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(NAME)),
                getChainId(),
                address(this)
            )
        );

    uint256 private _totalSupply;
    mapping(address => Account) private accounts;
    address[] public accountsIndex;
    uint256 public totalVotes;
    Proposal[] private proposals;
    mapping(uint256 => mapping(address => bool)) public voted;

    event DelegateUpdated(
        address indexed oldDelegatee,
        address indexed delegatee,
        uint256 votes
    );
    event Committed(
        address indexed user,
        uint256 tokens,
        uint256 balance,
        uint256 duration,
        uint256 end,
        address delegatee,
        uint256 votes,
        uint256 totalVotes
    );
    event Recommitted(
        address indexed user,
        uint256 elapsed,
        uint256 reward,
        uint256 callerReward,
        uint256 balance,
        uint256 duration,
        uint256 end,
        uint256 votes,
        uint256 totalVotes
    );
    event Uncommitted(
        address indexed user,
        uint256 tokens,
        uint256 reward,
        uint256 balance,
        uint256 duration,
        uint256 end,
        uint256 votes,
        uint256 totalVotes
    );
    event Proposed(
        address indexed proposer,
        uint256 id,
        string description,
        address[] targets,
        uint256[] value,
        bytes[] data,
        uint256 start
    );
    event Voted(
        address indexed user,
        uint256 id,
        bool support,
        uint256 votes,
        uint256 forVotes,
        uint256 againstVotes
    );
    event Executed(address indexed user, uint256 id);

    constructor(
        OGTokenInterface ogToken,
        OGDTokenInterface ogdToken,
        CurveInterface ogRewardCurve,
        CurveInterface voteWeightCurve
    ) OptinoGovBase(ogToken, ogdToken, ogRewardCurve, voteWeightCurve) {}

    function symbol() external pure override returns (string memory) {
        return NAME;
    }

    function name() external pure override returns (string memory) {
        return NAME;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply - accounts[address(0)].balance;
    }

    function balanceOf(address tokenOwner)
        external
        view
        override
        returns (uint256 balance)
    {
        return accounts[tokenOwner].balance;
    }

    function transfer(address to, uint256 tokens)
        external
        override
        returns (bool success)
    {
        require(false, "Unimplemented");
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens)
        external
        override
        returns (bool success)
    {
        require(false, "Unimplemented");
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external override returns (bool success) {
        require(false, "Unimplemented");
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(
        address, /*tokenOwner*/
        address /*spender*/
    ) external pure override returns (uint256 remaining) {
        return 0;
    }

    function getAccountByIndex(uint256 i)
        public
        view
        returns (address tokenOwner, Account memory account)
    {
        require(i < accountsIndex.length, "Invalid index");
        tokenOwner = accountsIndex[i];
        account = accounts[tokenOwner];
    }

    function accountsLength() public view returns (uint256) {
        return accountsIndex.length;
    }

    function delegate(address delegatee) public {
        require(
            delegatee == address(0) || accounts[delegatee].end != 0,
            "delegatee not registered"
        );
        require(msg.sender != delegatee, "Cannot delegate to self");
        Account storage account = accounts[msg.sender];
        require(
            uint256(account.lastVoted) + votingDuration < block.timestamp,
            "Cannot delegate after recent vote"
        );
        require(
            uint256(account.lastDelegated) + votingDuration < block.timestamp,
            "Cannot vote after recent delegation"
        );
        address oldDelegatee = account.delegatee;
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes -= account.votes;
        }
        account.delegatee = delegatee;
        account.lastDelegated = uint64(block.timestamp);
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes += account.votes;
        }
        emit DelegateUpdated(oldDelegatee, delegatee, account.votes);
    }

    function updateStatsBefore(Account storage account) internal {
        totalVotes -= account.votes;
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes -= account.votes;
        }
    }

    function updateStatsAfter(Account storage account) internal {
        uint256 rate = voteWeightCurve.getRate(uint256(account.duration));
        account.votes = (account.balance * rate) / 1e18;
        totalVotes += account.votes;
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes += account.votes;
        }
    }

    function accruedReward(address tokenOwner)
        public
        view
        returns (uint256 _reward, uint256 _term)
    {
        return _calculateReward(accounts[tokenOwner]);
    }

    function _calculateReward(Account memory account)
        internal
        view
        returns (uint256 _reward, uint256 _term)
    {
        uint256 from = account.end == 0
            ? block.timestamp
            : uint256(account.end) - uint256(account.duration);
        uint256 futureValue = InterestUtils.futureValue(
            account.balance,
            from,
            block.timestamp,
            account.rate
        );
        _reward = futureValue - account.balance;
        _term = block.timestamp - from;
    }

    function _getOGRewardRate(uint256 term)
        internal
        view
        returns (uint256 rate)
    {
        try ogRewardCurve.getRate(term) returns (uint256 _rate) {
            rate = _rate;
        } catch {
            rate = 0;
        }
    }

    // commit(tokens, duration) - tokens can be 0 for a recommit, duration can be 0
    // uncommit(tokens) - tokens can be 0 to uncommit all
    // uncommitFor(tokens) by different msg.sender for a %fee, only after may need a time delay
    function _changeCommitment(
        address tokenOwner,
        uint256 depositTokens,
        uint256 withdrawTokens,
        bool withdrawRewards,
        uint256 duration
    ) internal {
        Account storage account = accounts[tokenOwner];
        if (depositTokens > 0) {
            require(duration > 0, "Duration must be > 0");
        }
        if (withdrawTokens > 0) {
            require(
                uint256(account.end) < block.timestamp,
                "Commitment still active"
            );
            require(withdrawTokens <= account.balance, "Unsufficient balance");
        }
        updateStatsBefore(account);
        (uint256 reward, uint256 elapsed) = _calculateReward(account);
        uint256 availableToMint = ogToken.availableToMint();
        if (reward > availableToMint) {
            reward = availableToMint;
        }
        uint256 callerReward;
        if (reward > 0) {
            if (withdrawRewards) {
                require(ogToken.mint(tokenOwner, reward), "OG mint failed");
            } else {
                if (msg.sender != tokenOwner) {
                    callerReward = (reward * collectRewardForFee) / 1e18;
                    if (callerReward > 0) {
                        reward -= callerReward;
                        require(
                            ogToken.mint(msg.sender, callerReward),
                            "OG mint failed"
                        );
                    }
                }
                require(ogToken.mint(address(this), reward), "OG mint failed");
                account.balance += reward;
                _totalSupply += reward;
                require(ogdToken.mint(tokenOwner, reward), "OGD mint failed");
                emit Transfer(address(0), tokenOwner, reward);
            }
        }
        if (depositTokens > 0) {
            if (account.end == 0) {
                uint256 rate = _getOGRewardRate(duration);
                accounts[tokenOwner] = Account(
                    uint64(duration),
                    uint64(block.timestamp + duration),
                    uint64(0),
                    uint64(0),
                    uint64(accountsIndex.length),
                    address(0),
                    rate,
                    depositTokens,
                    0,
                    0
                );
                account = accounts[tokenOwner];
                accountsIndex.push(tokenOwner);
            } else {
                require(
                    block.timestamp + duration >= account.end,
                    "Cannot shorten duration"
                );
                account.duration = uint64(duration);
                account.end = uint64(block.timestamp + duration);
                account.rate = _getOGRewardRate(duration);
                account.balance += depositTokens;
            }
            require(
                ogdToken.mint(tokenOwner, depositTokens),
                "OGD mint failed"
            );
            // TODO account.votes not updated. remove remaining variables
            _totalSupply += depositTokens;
            emit Transfer(address(0), tokenOwner, depositTokens);
        } else if (withdrawTokens > 0) {
            _totalSupply -= withdrawTokens;
            account.balance -= withdrawTokens;
            if (account.balance == 0) {
                uint256 removedIndex = uint256(account.index);
                uint256 lastIndex = accountsIndex.length - 1;
                address lastAccountAddress = accountsIndex[lastIndex];
                accountsIndex[removedIndex] = lastAccountAddress;
                accounts[lastAccountAddress].index = uint64(removedIndex);
                delete accountsIndex[lastIndex];
                delete accounts[tokenOwner];
                if (accountsIndex.length > 0) {
                    accountsIndex.pop();
                }
            }
            // TODO: Check
            account.duration = uint64(0);
            account.end = uint64(block.timestamp);
            require(
                ogdToken.burnFrom(tokenOwner, withdrawTokens),
                "OG burnFrom failed"
            );
            require(
                ogToken.transfer(tokenOwner, withdrawTokens),
                "OG transfer failed"
            );
        } else {
            // require(block.timestamp + duration >= account.end, "Cannot shorten duration");
            account.duration = uint64(duration);
            account.end = uint64(block.timestamp + duration);
        }
        updateStatsAfter(account);
        if (depositTokens > 0) {
            emit Committed(
                tokenOwner,
                depositTokens,
                account.balance,
                account.duration,
                account.end,
                account.delegatee,
                account.votes,
                totalVotes
            );
        } else if (withdrawTokens > 0) {
            emit Uncommitted(
                tokenOwner,
                withdrawTokens,
                reward,
                account.balance,
                account.duration,
                account.end,
                account.votes,
                totalVotes
            );
        } else {
            emit Recommitted(
                tokenOwner,
                elapsed,
                reward,
                callerReward,
                account.balance,
                account.duration,
                account.end,
                account.votes,
                totalVotes
            );
        }
    }

    function commit(uint256 tokens, uint256 duration) public {
        // require(duration > 0, "duration must be > 0");
        require(
            ogToken.transferFrom(msg.sender, address(this), tokens),
            "OG transferFrom failed"
        );
        _changeCommitment(msg.sender, tokens, 0, false, duration);
    }

    function uncommit(uint256 tokens) public {
        if (tokens == 0) {
            tokens = accounts[msg.sender].balance;
            uint256 ogdTokens = ogdToken.balanceOf(msg.sender);
            if (ogdTokens < tokens) {
                tokens = ogdTokens;
            }
        }
        require(accounts[msg.sender].balance > 0, "No balance to uncommit");
        _changeCommitment(
            msg.sender,
            0,
            tokens,
            tokens == accounts[msg.sender].balance,
            0
        );
        emit Transfer(msg.sender, address(0), tokens);
    }

    function uncommitFor(address tokenOwner) public {
        require(
            accounts[tokenOwner].balance > 0,
            "tokenOwner has no balance to uncommit"
        );
        _changeCommitment(tokenOwner, 0, 0, false, 0);
    }

    function propose(
        string memory description,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data
    ) public returns (uint256) {
        // console.log("        > %s -> propose(description %s)", msg.sender, description);
        // require(accounts[msg.sender].votes >= totalVotes.mul(proposalThreshold).div(1e18), "OptinoGov: Not enough votes to propose");
        require(
            targets.length > 0 &&
                values.length == targets.length &&
                data.length == targets.length,
            "Invalid data"
        );
        Proposal storage proposal = proposals.push();
        proposal.start = uint64(block.timestamp);
        // proposal.executed = 0;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.targets = targets;
        proposal.values = values;
        proposal.data = data;
        // proposal.forVotes = 0;
        // proposal.againstVotes = 0;
        require(ogToken.burnFrom(msg.sender, proposalCost), "OG burn failed");
        emit Proposed(
            msg.sender,
            proposals.length - 1,
            description,
            proposal.targets,
            proposal.values,
            proposal.data,
            block.timestamp
        );
        return proposals.length - 1;
    }

    function getProposal(uint256 i)
        public
        view
        returns (
            uint64 start,
            uint32 executed,
            address proposer,
            string memory description,
            address[] memory targets,
            uint256[] memory _values,
            bytes[] memory data,
            uint256 forVotes,
            uint256 againstVotes
        )
    {
        require(i < proposals.length, "Invalid index");
        Proposal memory proposal = proposals[i];
        return (
            proposal.start,
            proposal.executed,
            proposal.proposer,
            proposal.description,
            proposal.targets,
            proposal.values,
            proposal.data,
            proposal.forVotes,
            proposal.againstVotes
        );
    }

    function proposalsLength() public view returns (uint256) {
        return proposals.length;
    }

    function vote(uint256 id, bool support) public {
        _vote(msg.sender, id, support);
    }

    function _vote(
        address voter,
        uint256 id,
        bool support
    ) internal {
        Proposal storage proposal = proposals[id];
        require(
            proposal.start != 0 &&
                block.timestamp < uint256(proposal.start) + votingDuration,
            "Voting closed"
        );
        require(
            accounts[voter].lastDelegated + votingDuration < block.timestamp,
            "Cannot vote after recent delegation"
        );
        require(!voted[id][voter], "Already voted");
        uint256 votes = accounts[voter].votes + accounts[voter].delegatedVotes;
        if (accounts[voter].delegatee != address(0)) {
            if (support) {
                proposal.forVotes += votes;
            } else {
                proposal.againstVotes += votes;
            }
            uint256 _voteReward = (accounts[voter].votes * voteReward) / 1e18;
            if (_voteReward > 0) {
                require(ogToken.mint(voter, _voteReward), "OG mint failed");
            }
        }
        voted[id][voter] = true;
        accounts[voter].lastVoted = uint64(block.timestamp);
        emit Voted(
            voter,
            id,
            support,
            votes,
            proposal.forVotes,
            proposal.againstVotes
        );
    }

    function voteDigest(uint256 id, bool support)
        public
        view
        returns (bytes32 digest)
    {
        bytes32 structHash = keccak256(
            abi.encode(EIP712_VOTE_TYPEHASH, id, support)
        );
        digest = keccak256(
            abi.encodePacked("\x19\x01", EIP712_DOMAIN_SEPARATOR, structHash)
        );
    }

    function voteBySigs(uint256 id, bytes[] memory sigs) public {
        for (uint256 i = 0; i < sigs.length; i++) {
            bytes memory sig = sigs[i];
            bytes32 digest = voteDigest(id, true);
            address voter = ecrecoverFromSig(digest, sig);
            if (voter != address(0) && accounts[voter].balance > 0) {
                if (!voted[id][voter]) {
                    _vote(voter, id, true);
                }
            } else {
                digest = voteDigest(id, false);
                voter = ecrecoverFromSig(digest, sig);
                if (voter != address(0) && accounts[voter].balance > 0) {
                    if (!voted[id][voter]) {
                        _vote(voter, id, false);
                    }
                }
            }
        }
    }

    // TODO
    function execute(uint256 id) public {
        Proposal storage proposal = proposals[id];
        // require(proposal.start != 0 && block.timestamp >= proposal.start.add(votingDuration).add(executeDelay));

        // if (quorum > currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks)) {
        //     return quorum.sub(currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks));
        // } else {
        //     return 0;
        // }

        // require(proposal.forVotes >= totalVotes.mul(quorum).div(1e18), "OptinoGov: Not enough votes to execute");
        proposal.executed = 1;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{
                value: proposal.values[i]
            }(proposal.data[i]);
            require(success, "Execution failed");
        }

        emit Executed(msg.sender, id);
    }

    receive() external payable {
        // TODO depositDividend(address(0), msg.value);
    }
}
