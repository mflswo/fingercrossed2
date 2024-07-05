// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/GaussianCDF.sol";

contract GaussianCDFTest is Test {
    GaussianCDF private gaussianCDF;
    int256 private constant SQRT_2 = 1414213562373095048; // sqrt(2) * 1e18
    int256 private constant FIXED_1 = 1e18;
    uint256 private constant EPSILON = 10*1e10; // 1e-8 in fixed point
    
    struct TestCase {
        int256 x;
        int256 mu;
        int256 sigma;
        int256 expected;
    }

    TestCase[] private testCases;

   

    function setUp() public {
        gaussianCDF = new GaussianCDF();

         // Add test cases with pre-computed results
        testCases.push(TestCase(0, 0, FIXED_1, 500000000000000000)); // Φ(0) ≈ 0.5
        testCases.push(TestCase(FIXED_1, 0, FIXED_1, 841344746068543720)); // Φ(1) ≈ 0.8413447460685429
        testCases.push(TestCase(-FIXED_1, 0, FIXED_1, 158655253931456280)); // Φ(-1) ≈ 0.15865525393145707
        testCases.push(TestCase(2 * FIXED_1, 0, FIXED_1, 977249868051821010)); // Φ(2) ≈ 0.9772498680518208
        testCases.push(TestCase(-2 * FIXED_1, 0, FIXED_1, 22750131948178990)); // Φ(-2) ≈ 0.02275013194817921
        testCases.push(TestCase(3 * FIXED_1, 1 * FIXED_1, FIXED_1, 977249868051821010)); // Φ((3-1)/1) = Φ(2) ≈ 0.9772498680518208
        testCases.push(TestCase(0, -1 * FIXED_1, 2 * FIXED_1, 691462461274012980)); // Φ((0-(-1))/2) = Φ(0.5) ≈ 0.6914624612740131
    }

    function testBasicCases() public {
        assertApproxEqAbs(gaussianCDF.gaussianCDF(0, 0, FIXED_1), FIXED_1 / 2, EPSILON, "CDF(0, 0, 1) should be ~0.5");
        assertApproxEqAbs(gaussianCDF.gaussianCDF(FIXED_1, 0, FIXED_1), 841344746068543720, EPSILON, "CDF(1, 0, 1) should be ~0.8413447460685429");
        assertApproxEqAbs(gaussianCDF.gaussianCDF(-FIXED_1, 0, FIXED_1), 158655253931456280, EPSILON, "CDF(-1, 0, 1) should be ~0.15865525393145707");
    }

    function testExtremeCases() public {
        assertApproxEqAbs(gaussianCDF.gaussianCDF(1e23, 0, FIXED_1), FIXED_1, EPSILON, "CDF of very large x should approach 1");
        assertApproxEqAbs(gaussianCDF.gaussianCDF(-1e23, 0, FIXED_1), 0, EPSILON, "CDF of very small x should approach 0");
    }

    function testDifferentMuSigma() public {
        assertApproxEqAbs(gaussianCDF.gaussianCDF(2e18, 1e18, 1e18), 841344746068543720, EPSILON, "CDF(2, 1, 1) should be ~0.8413447460685429");
        assertApproxEqAbs(gaussianCDF.gaussianCDF(0, -1e18, 2e18), 691462461274012990, EPSILON, "CDF(0, -1, 2) should be ~0.6914624612740130");
    }

    function testEdgeCases() public {
        assertApproxEqAbs(gaussianCDF.gaussianCDF(0, 1e20, 1e15), 0, EPSILON, "CDF with very large mu");
        assertApproxEqAbs(gaussianCDF.gaussianCDF(0, -1e20, 1e15), FIXED_1, EPSILON, "CDF with very small mu");
        assertApproxEqAbs(gaussianCDF.gaussianCDF(0, 0, 1e19), FIXED_1 / 2, EPSILON, "CDF with very large sigma");
    }

    function testFuzzGaussianCDF(int256 x, int256 mu, int256 sigma) public {
        x = bound(x, -1e23, 1e23);
        mu = bound(mu, -1e20, 1e20);
        sigma = bound(sigma, 1, 1e19);

        int256 result = gaussianCDF.gaussianCDF(x, mu, sigma);
        assertTrue(result >= 0 && result <= FIXED_1, "CDF result should be between 0 and 1");
    }

function testErrorBounds() public {
    for (uint i = 0; i < testCases.length; i++) {
            TestCase memory tc = testCases[i];
            int256 result = gaussianCDF.gaussianCDF(tc.x, tc.mu, tc.sigma);
            uint256 absoluteError = uint256(abs(result - tc.expected));

            console.log("Test case:", uint256(i));
            console.log("x:", uint256(tc.x));
            console.log("mu:", uint256(tc.mu));
            console.log("sigma:", uint256(tc.sigma));
            console.log("Result:", uint256(result));
            console.log("Expected:", uint256(tc.expected));
            console.log("Error:", absoluteError);

            assertTrue(absoluteError <= EPSILON, "Error exceeds bounds");
        }
}

    function testInvalidInputs() public {
        vm.expectRevert("Invalid sigma");
        gaussianCDF.gaussianCDF(0, 0, 0);

        vm.expectRevert("Invalid sigma");
        gaussianCDF.gaussianCDF(0, 0, -1);

        vm.expectRevert("Invalid sigma");
        gaussianCDF.gaussianCDF(0, 0, 1e38);

        vm.expectRevert("Invalid mu");
        gaussianCDF.gaussianCDF(0, 1e39, FIXED_1);

        vm.expectRevert("Invalid mu");
        gaussianCDF.gaussianCDF(0, -1e39, FIXED_1);

        vm.expectRevert("Invalid x");
        gaussianCDF.gaussianCDF(1e42, 0, FIXED_1);

        vm.expectRevert("Invalid x");
        gaussianCDF.gaussianCDF(-1e42, 0, FIXED_1);
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function sign(int256 x) private pure returns (int256) {
        return x >= 0 ? int256(1) : int256(-1);
    }
}