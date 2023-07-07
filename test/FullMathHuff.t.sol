// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {FullMath} from "../src/FullMath.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {Test} from "forge-std/Test.sol";

/**
 * @dev Tests copied from https://github.com/Vectorized/solady/blob/main/test/FixedPointMathLib.t.sol
 */
contract FullMathHuffTest is Test {
    FullMath fullMathLibrary;

    function setUp() public {
        fullMathLibrary = FullMath(HuffDeployer.deploy("FullMathHuff"));
    }

    function testHuffMulDiv() public {
        assertEq(fullMathLibrary.mulDiv(2.5e27, 0.5e27, 1e27), 1.25e27);
        assertEq(fullMathLibrary.mulDiv(2.5e18, 0.5e18, 1e18), 1.25e18);
        assertEq(fullMathLibrary.mulDiv(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(fullMathLibrary.mulDiv(369, 271, 1e2), 999);

        assertEq(fullMathLibrary.mulDiv(1e27, 1e27, 2e27), 0.5e27);
        assertEq(fullMathLibrary.mulDiv(1e18, 1e18, 2e18), 0.5e18);
        assertEq(fullMathLibrary.mulDiv(1e8, 1e8, 2e8), 0.5e8);

        assertEq(fullMathLibrary.mulDiv(2e27, 3e27, 2e27), 3e27);
        assertEq(fullMathLibrary.mulDiv(3e18, 2e18, 3e18), 2e18);
        assertEq(fullMathLibrary.mulDiv(2e8, 3e8, 2e8), 3e8);
    }

    function testHuffMulDivEdgeCases() public {
        assertEq(fullMathLibrary.mulDiv(0, 1e18, 1e18), 0);
        assertEq(fullMathLibrary.mulDiv(1e18, 0, 1e18), 0);
        assertEq(fullMathLibrary.mulDiv(0, 0, 1e18), 0);
    }

    function testHuffMulDivZeroDenominatorReverts() public {
        vm.expectRevert();
        fullMathLibrary.mulDiv(1e18, 1e18, 0);
    }

    function testHuffMulDivUp() public {
        assertEq(
            fullMathLibrary.mulDivRoundingUp(2.5e27, 0.5e27, 1e27),
            1.25e27
        );
        assertEq(
            fullMathLibrary.mulDivRoundingUp(2.5e18, 0.5e18, 1e18),
            1.25e18
        );
        assertEq(fullMathLibrary.mulDivRoundingUp(2.5e8, 0.5e8, 1e8), 1.25e8);
        assertEq(fullMathLibrary.mulDivRoundingUp(369, 271, 1e2), 1000);

        assertEq(fullMathLibrary.mulDivRoundingUp(1e27, 1e27, 2e27), 0.5e27);
        assertEq(fullMathLibrary.mulDivRoundingUp(1e18, 1e18, 2e18), 0.5e18);
        assertEq(fullMathLibrary.mulDivRoundingUp(1e8, 1e8, 2e8), 0.5e8);

        assertEq(fullMathLibrary.mulDivRoundingUp(2e27, 3e27, 2e27), 3e27);
        assertEq(fullMathLibrary.mulDivRoundingUp(3e18, 2e18, 3e18), 2e18);
        assertEq(fullMathLibrary.mulDivRoundingUp(2e8, 3e8, 2e8), 3e8);
    }

    function testHuffMulDivUpEdgeCases() public {
        assertEq(fullMathLibrary.mulDivRoundingUp(0, 1e18, 1e18), 0);
        assertEq(fullMathLibrary.mulDivRoundingUp(1e18, 0, 1e18), 0);
        assertEq(fullMathLibrary.mulDivRoundingUp(0, 0, 1e18), 0);
    }

    function testHuffMulDivUpZeroDenominator() public {
        vm.expectRevert();
        fullMathLibrary.mulDivRoundingUp(1e18, 1e18, 0);
    }

    function testHuffFullMulDiv() public {
        assertEq(fullMathLibrary.mulDiv(0, 0, 1), 0);
        assertEq(fullMathLibrary.mulDiv(4, 4, 2), 8);
        assertEq(
            fullMathLibrary.mulDiv(2 ** 200, 2 ** 200, 2 ** 200),
            2 ** 200
        );
    }

    function testHuffFullMulDivUpRevertsIfRoundedUpResultOverflowsCase1()
        public
    {
        vm.expectRevert();
        fullMathLibrary.mulDivRoundingUp(
            535006138814359,
            432862656469423142931042426214547535783388063929571229938474969,
            2
        );
    }

    function testHuffFullMulDivUpRevertsIfRoundedUpResultOverflowsCase2()
        public
    {
        vm.expectRevert();
        fullMathLibrary.mulDivRoundingUp(
            115792089237316195423570985008687907853269984659341747863450311749907997002549,
            115792089237316195423570985008687907853269984659341747863450311749907997002550,
            115792089237316195423570985008687907853269984653042931687443039491902864365164
        );
    }

    function testHuffFullMulDiv(
        uint256 a,
        uint256 b,
        uint256 d
    ) public returns (uint256 result) {
        if (d == 0) {
            vm.expectRevert();
            fullMathLibrary.mulDiv(a, b, d);
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
            fullMathLibrary.mulDiv(a, b, d);
            return 0;
        }

        uint256 q = fullMathLibrary.mulDiv(a, b, d);
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

    function testHuffFullMulDivUp(uint256 a, uint256 b, uint256 d) public {
        uint256 mulDivResult = testHuffFullMulDiv(a, b, d);
        if (mulDivResult != 0) {
            uint256 expectedResult = mulDivResult;
            if (mulmod(a, b, d) > 0) {
                if (!(mulDivResult < type(uint256).max)) {
                    vm.expectRevert();
                    fullMathLibrary.mulDivRoundingUp(a, b, d);
                    return;
                }
                expectedResult++;
            }
            assertEq(fullMathLibrary.mulDivRoundingUp(a, b, d), expectedResult);
        }
    }

    function testHuffMulDiv(uint256 x, uint256 y, uint256 denominator) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(
            fullMathLibrary.mulDiv(x, y, denominator),
            (x * y) / denominator
        );
    }

    function testHuffMulDivZeroDenominatorReverts(uint256 x, uint256 y) public {
        vm.expectRevert();
        fullMathLibrary.mulDiv(x, y, 0);
    }

    function testHuffMulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) public {
        // Ignore cases where x * y overflows or denominator is 0.
        unchecked {
            if (denominator == 0 || (x != 0 && (x * y) / x != y)) return;
        }

        assertEq(
            fullMathLibrary.mulDivRoundingUp(x, y, denominator),
            x * y == 0 ? 0 : (x * y - 1) / denominator + 1
        );
    }

    function testHuffMulDivUpZeroDenominatorReverts(
        uint256 x,
        uint256 y
    ) public {
        vm.expectRevert();
        fullMathLibrary.mulDivRoundingUp(x, y, 0);
    }
}
