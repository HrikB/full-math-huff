// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {FullMath} from "../src/FullMath.sol";
import {Test} from "forge-std/Test.sol";

import "forge-std/console.sol";

/**
 * @dev Tests copied from https://github.com/Vectorized/solady/blob/main/test/FixedPointMathLib.t.sol
 */
contract FullMathTest is Test {
    function testMulDiv() public {
        assertEq(FullMath.mulDiv(2.5e27, 0.5e27, 1e27), 1.25e27);
        assertEq(FullMath.mulDiv(2.5e18, 0.5e18, 1e18), 1.25e18);
        assertEq(FullMath.mulDiv(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(FullMath.mulDiv(369, 271, 1e2), 999);

        assertEq(FullMath.mulDiv(1e27, 1e27, 2e27), 0.5e27);
        assertEq(FullMath.mulDiv(1e18, 1e18, 2e18), 0.5e18);
        assertEq(FullMath.mulDiv(1e8, 1e8, 2e8), 0.5e8);

        assertEq(FullMath.mulDiv(2e27, 3e27, 2e27), 3e27);
        assertEq(FullMath.mulDiv(3e18, 2e18, 3e18), 2e18);
        assertEq(FullMath.mulDiv(2e8, 3e8, 2e8), 3e8);
    }

    function testMulDivEdgeCases() public {
        assertEq(FullMath.mulDiv(0, 1e18, 1e18), 0);
        assertEq(FullMath.mulDiv(1e18, 0, 1e18), 0);
        assertEq(FullMath.mulDiv(0, 0, 1e18), 0);
    }

    function testMulDivZeroDenominatorReverts() public {
        vm.expectRevert();
        FullMath.mulDiv(1e18, 1e18, 0);
    }

    function testMulDivUp() public {
        assertEq(FullMath.mulDivRoundingUp(2.5e27, 0.5e27, 1e27), 1.25e27);
        assertEq(FullMath.mulDivRoundingUp(2.5e18, 0.5e18, 1e18), 1.25e18);
        assertEq(FullMath.mulDivRoundingUp(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(FullMath.mulDivRoundingUp(369, 271, 1e2), 1000);

        assertEq(FullMath.mulDivRoundingUp(1e27, 1e27, 2e27), 0.5e27);
        assertEq(FullMath.mulDivRoundingUp(1e18, 1e18, 2e18), 0.5e18);
        assertEq(FullMath.mulDivRoundingUp(1e8, 1e8, 2e8), 0.5e8);

        assertEq(FullMath.mulDivRoundingUp(2e27, 3e27, 2e27), 3e27);
        assertEq(FullMath.mulDivRoundingUp(3e18, 2e18, 3e18), 2e18);
        assertEq(FullMath.mulDivRoundingUp(2e8, 3e8, 2e8), 3e8);
    }

    function testMulDivUpEdgeCases() public {
        assertEq(FullMath.mulDivRoundingUp(0, 1e18, 1e18), 0);
        assertEq(FullMath.mulDivRoundingUp(1e18, 0, 1e18), 0);
        assertEq(FullMath.mulDivRoundingUp(0, 0, 1e18), 0);
    }

    function testMulDivUpZeroDenominator() public {
        vm.expectRevert();
        FullMath.mulDivRoundingUp(1e18, 1e18, 0);
    }

    function testFullMulDiv() public {
        assertEq(FullMath.mulDiv(0, 0, 1), 0);
        assertEq(FullMath.mulDiv(4, 4, 2), 8);
        assertEq(FullMath.mulDiv(2 ** 200, 2 ** 200, 2 ** 200), 2 ** 200);
    }

    function testFullMulDivUpRevertsIfRoundedUpResultOverflowsCase1() public {
        vm.expectRevert();
        FullMath.mulDivRoundingUp(
            535006138814359,
            432862656469423142931042426214547535783388063929571229938474969,
            2
        );
    }

    function testFullMulDivUpRevertsIfRoundedUpResultOverflowsCase2() public {
        vm.expectRevert();
        FullMath.mulDivRoundingUp(
            115792089237316195423570985008687907853269984659341747863450311749907997002549,
            115792089237316195423570985008687907853269984659341747863450311749907997002550,
            115792089237316195423570985008687907853269984653042931687443039491902864365164
        );
    }

    function testFullMulDiv(
        uint256 a,
        uint256 b,
        uint256 d
    ) public returns (uint256 result) {
        if (d == 0) {
            vm.expectRevert();
            FullMath.mulDiv(a, b, d);
            return 0;
        }

        // Compute a * b in Chinese Remainder Basis
        uint256 expectedA;
        uint256 expectedB;
        unchecked {
            expectedA = a * b;
            expectedB = mulmod(a, b, 2 ** 256 - 1);
        }

        // Construct a * b
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
        if (prod1 >= d) {
            vm.expectRevert();
            FullMath.mulDiv(a, b, d);
            return 0;
        }

        uint256 q = FullMath.mulDiv(a, b, d);
        uint256 r = mulmod(a, b, d);

        // Compute q * d + r in Chinese Remainder Basis
        uint256 actualA;
        uint256 actualB;
        unchecked {
            actualA = q * d + r;
            actualB = addmod(mulmod(q, d, 2 ** 256 - 1), r, 2 ** 256 - 1);
        }

        assertEq(actualA, expectedA);
        assertEq(actualB, expectedB);
        return q;
    }

    function testFullMulDivUp(uint256 a, uint256 b, uint256 d) public {
        uint256 mulDivResult = testFullMulDiv(a, b, d);
        if (mulDivResult != 0) {
            uint256 expectedResult = mulDivResult;
            if (mulmod(a, b, d) > 0) {
                if (!(mulDivResult < type(uint256).max)) {
                    vm.expectRevert();
                    FullMath.mulDivRoundingUp(a, b, d);
                    return;
                }
                expectedResult++;
            }
            assertEq(FullMath.mulDivRoundingUp(a, b, d), expectedResult);
        }
    }

    function testMulDiv(uint256 x, uint256 y, uint256 denominator) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(FullMath.mulDiv(x, y, denominator), (x * y) / denominator);
    }

    function testMulDivZeroDenominatorReverts(uint256 x, uint256 y) public {
        vm.expectRevert();
        FullMath.mulDiv(x, y, 0);
    }

    function testMulDivUp(uint256 x, uint256 y, uint256 denominator) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(
            FullMath.mulDivRoundingUp(x, y, denominator),
            x * y == 0 ? 0 : (x * y - 1) / denominator + 1
        );
    }

    function testMulDivUpZeroDenominatorReverts(uint256 x, uint256 y) public {
        vm.expectRevert();
        FullMath.mulDivRoundingUp(x, y, 0);
    }
}
