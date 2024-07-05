// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Test.sol";

contract GaussianCDF {
    int256 private constant FIXED_1 = 1e18;
    int256 private constant SQRT_2 = 1414213562373095049; // sqrt(2) * 1e18

    // Polynomial coefficients scaled by 1e18
    int256 private constant p = 327591100000000000; // 0.3275911 * 1e18
    int256 private constant a1 = 254829592000000000;
    int256 private constant a2 = -284496736000000000;
    int256 private constant a3 = 1421413741000000000;
    int256 private constant a4 = -1453152027000000000;
    int256 private constant a5 = 1061405429000000000;

  function gaussianCDF(int256 x, int256 mu, int256 sigma) public pure returns (int256) {
    require(sigma > 0 && sigma <= 1e37, "Invalid sigma");
    require(mu >= -1e38 && mu <= 1e38, "Invalid mu");
    require(x >= -1e41 && x <= 1e41, "Invalid x");

    // Handle extreme cases
    if (x >= mu + 8 * sigma) return FIXED_1;  // Approximately 1
    if (x <= mu - 8 * sigma) return 0;        // Approximately 0

    // Use a safer calculation for z
    int256 z;
    if (x > mu) {
        z = ((x - mu) * FIXED_1) / sigma;
    } else {
        z = -((mu - x) * FIXED_1) / sigma;
    }

    int256 erfInput = (z * FIXED_1) / SQRT_2;
    int256 erfValue = erf(erfInput);

    return (FIXED_1 + erfValue) / 2;
}

    function erf(int256 x) private pure returns (int256) {
        int256 sign = x >= 0 ? FIXED_1 : -FIXED_1;
        int256 absX = abs(x);

        // Compute t = 1 / (1 + px)
        int256 t = FIXED_1 * FIXED_1 / (FIXED_1 + (p * absX) / FIXED_1);

        // Compute e^(-x²)
        int256 xSquared = (absX * absX) / FIXED_1;
        int256 exponent = exp(-xSquared);

        // Compute polynomial
        int256 polynomial = errf(t);

        // Combine all parts: 1 - polynomial * e^(-x²)
        int256 result = FIXED_1 - (polynomial * exponent) / FIXED_1;

        return (sign * result) / FIXED_1;
    }

    function errf(int256 t) private pure returns (int256) {
        // Horner's method: a1*t + a2*t^2 + a3*t^3 + a4*t^4 + a5*t^5
        int256 y = a5;
        y = (y * t) / FIXED_1 + a4;
        y = (y * t) / FIXED_1 + a3;
        y = (y * t) / FIXED_1 + a2;
        y = (y * t) / FIXED_1 + a1;
        y = (y * t) / FIXED_1;

        return y;
    }

   function exp(int256 x) private pure returns (int256) {
        // If x is very small, return 1
        if (x > -1e6 && x < 1e6) return FIXED_1;

        // If x is too large, return max value to avoid overflow
        if (x >= 135305999368893231588) return type(int256).max;

        // If x is too small, return 0 to avoid underflow
        if (x <= -41446531673892822322) return 0;

        // Compute e^(x) using the identity: e^x = (e^(x/2))^2
        // This allows us to reduce the range of x and improve accuracy
        if (x < 0) {
            int256 z = exp(-x);
            return z == 0 ? FIXED_1 : (FIXED_1 * FIXED_1) / z;
        }

        int256 y = x;
        int256 result = FIXED_1;
        int256 term = FIXED_1;

        for (int256 i = 1; i <= 36; i++) {
            term = (term * y) / (i * FIXED_1);
            result += term;
            // if (term <= 1e5) {
            //     break;
            // }
        }

        return result;
    }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}