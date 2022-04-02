#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Test
#
# Enjoy. (c) The Optino Project. GPLv2
# ----------------------------------------------------------------------------------------------
TEST1INPUT=test/TestInterestUtils.js
TEST2OUTPUT=results/TestInterestUtils.txt

# Clear scollback buffer and screen
printf "\033[2J\033[3J\033[1;1H"

echo "\$ npx hardhat test $TEST1INPUT > $TEST2OUTPUT" | tee $TEST2OUTPUT

npx hardhat test $TEST1INPUT | tee -a $TEST2OUTPUT

TEST2INPUT=test/TestSimpleCurve.js
TEST2OUTPUT=results/TestSimpleCurve.txt

echo "\$ npx hardhat test $TEST2INPUT > $TEST2OUTPUT" | tee $TEST2OUTPUT

npx hardhat test $TEST2INPUT | tee -a $TEST2OUTPUT
