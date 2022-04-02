#!/bin/sh
# ----------------------------------------------------------------------------------------------
# Flatten solidity files
#
# Enjoy. (c) The Optino Project. GPLv2
# ----------------------------------------------------------------------------------------------

echo "\$ rm -rf flattened/ ..."
rm -rf flattened/
echo "\$ mkdir flattened/ ..."
mkdir flattened/
echo "\$ truffle-flattener contracts/OGToken.sol > flattened/OGToken_flattened.sol ..."
truffle-flattener contracts/OGToken.sol > flattened/OGToken_flattened.sol
echo "\$ truffle-flattener contracts/OGDToken.sol > flattened/OGDToken_flattened.sol ..."
truffle-flattener contracts/OGDToken.sol > flattened/OGDToken_flattened.sol
echo "\$ truffle-flattener contracts/OptinoGov.sol > flattened/OptinoGov_flattened.sol ..."
truffle-flattener contracts/OptinoGov.sol > flattened/OptinoGov_flattened.sol
echo "\$ truffle-flattener contracts/StakingFactory.sol > flattened/StakingFactory_flattened.sol ..."
truffle-flattener contracts/StakingFactory.sol > flattened/StakingFactory_flattened.sol
echo "\$ truffle-flattener contracts/POAPOGTokenStation.sol > flattened/POAPOGTokenStation_flattened.sol ..."
truffle-flattener contracts/POAPOGTokenStation.sol > flattened/POAPOGTokenStation_flattened.sol
echo "\$ truffle-flattener contracts/TestToken.sol > flattened/TestToken_flattened.sol ..."
truffle-flattener contracts/TestToken.sol > flattened/TestToken_flattened.sol
