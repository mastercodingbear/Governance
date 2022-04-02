#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Compile, flatten, enable all tests, execute all tests
#
# Enjoy. (c) The Optino Project. GPLv2
# ----------------------------------------------------------------------------------------------

# Clear scollback buffer and screen
printf "\033[2J\033[3J\033[1;1H"

# Exit if any command fails, including commands in a pipe
set -e
set -o pipefail

echo "Clean ..."
rm -rf ./artifacts/ ./cache/ ./flattened/ ./results/
mkdir flattened/ results/

echo "Compiling ..."
npx hardhat compile

echo "Flattening ..."
truffle-flattener contracts/OGToken.sol > flattened/OGToken_flattened.sol
truffle-flattener contracts/OGDToken.sol > flattened/OGDToken_flattened.sol
truffle-flattener contracts/OptinoGov.sol > flattened/OptinoGov_flattened.sol
truffle-flattener contracts/StakingFactory.sol > flattened/StakingFactory_flattened.sol
truffle-flattener contracts/POAPOGTokenStation.sol > flattened/POAPOGTokenStation_flattened.sol
truffle-flattener contracts/TestToken.sol > flattened/TestToken_flattened.sol

echo "Enabling all tests"
sed -i '' 's/describe.only/describe/g' test/*.js
sed -i '' 's/describe.skip/describe/g' test/*.js

echo "Test 1 - TestOptinoGov"
TEST1INPUT=test/TestOptinoGov.js
TEST1OUTPUT=results/TestOptinoGov.txt
echo "\$ npx hardhat test $TEST1INPUT > $TEST1OUTPUT" | tee $TEST1OUTPUT
npx hardhat test $TEST1INPUT | tee -a $TEST1OUTPUT

echo "Test 2 - TestOGDToken"
TEST2INPUT=test/TestOGDToken.js
TEST2OUTPUT=results/TestOGDToken.txt
echo "\$ npx hardhat test $TEST2INPUT > $TEST2OUTPUT" | tee $TEST2OUTPUT
npx hardhat test $TEST2INPUT | tee -a $TEST2OUTPUT

echo "Test 3 - TestStakingFactory"
TEST3INPUT=test/TestStakingFactory.js
TEST3OUTPUT=results/TestStakingFactory.txt
echo "\$ npx hardhat test $TEST3INPUT > $TEST3OUTPUT" | tee $TEST3OUTPUT
npx hardhat test $TEST3INPUT | tee -a $TEST3OUTPUT

echo "Test 4 - TestInterestUtils"
TEST4INPUT=test/TestInterestUtils.js
TEST4OUTPUT=results/TestInterestUtils.txt
echo "\$ npx hardhat test $TEST4INPUT > $TEST4OUTPUT" | tee $TEST4OUTPUT
npx hardhat test $TEST4INPUT | tee -a $TEST4OUTPUT

echo "Test 5 - TestSimpleCurve"
TEST5INPUT=test/TestSimpleCurve.js
TEST5OUTPUT=results/TestSimpleCurve.txt
echo "\$ npx hardhat test $TEST5INPUT > $TEST5OUTPUT" | tee $TEST5OUTPUT
npx hardhat test $TEST5INPUT | tee -a $TEST5OUTPUT
