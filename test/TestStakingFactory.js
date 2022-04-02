const { ZERO_ADDRESS, SECONDS_PER_DAY, SECONDS_PER_YEAR, ROLE, Data } = require('./helpers/common');
const { expect, assert } = require("chai");
const { BigNumber } = require("ethers");
const util = require('util');

let SimpleCurve;
let Staking;
let StakingFactory;
let OGToken;
let OGDToken;
let TestToken;
let data;
const verbose = false;

describe("TestStakingFactory", function() {
  beforeEach("Setup", async function() {
    OGToken = await ethers.getContractFactory("OGToken");
    OGDToken = await ethers.getContractFactory("OGDToken");
    SimpleCurve = await ethers.getContractFactory("SimpleCurve");
    Staking = await ethers.getContractFactory("Staking");
    StakingFactory = await ethers.getContractFactory("StakingFactory");
    TestToken = await ethers.getContractFactory("TestToken");
    data = new Data();
    await data.init();

    console.log("        --- Setup 1 - Deploy OGToken, FEE0, StakingFactory ---");
    let stakingRewardTerms = [SECONDS_PER_DAY, SECONDS_PER_YEAR, 2 * SECONDS_PER_YEAR];
    let stakingRewardRates = [BigNumber.from(SECONDS_PER_YEAR).mul(BigNumber.from(10).pow(10)), BigNumber.from(2 * SECONDS_PER_YEAR).mul(BigNumber.from(10).pow(10)), BigNumber.from(3 * SECONDS_PER_YEAR).mul(BigNumber.from(10).pow(10))];
    const setup1a = [];
    setup1a.push(OGToken.deploy("OG", "Optino Governance", 18, data.deployer, ethers.utils.parseUnits("0", 18)));
    setup1a.push(OGDToken.deploy("OGD", "Optino Governance Dividend", 18, data.deployer, ethers.utils.parseUnits("0", 18)));
    setup1a.push(SimpleCurve.deploy(stakingRewardTerms, stakingRewardRates));
    setup1a.push(TestToken.deploy("FEE0", "Fee0", 18, data.deployer, ethers.utils.parseUnits("100", 18)));
    const [ogToken, ogdToken, stakingRewardCurve, fee0Token] = await Promise.all(setup1a);
    const setup1b = [];
    setup1b.push(StakingFactory.deploy(ogToken.address, ogdToken.address, stakingRewardCurve.address));
    const [stakingFactory] = await Promise.all(setup1b);
    await data.setStakingFactoryData(ogToken, ogdToken, stakingRewardCurve, fee0Token, stakingFactory);

    await data.printTxData("ogTokenTx", ogToken.deployTransaction);
    await data.printTxData("fee0TokenTx", fee0Token.deployTransaction);
    await data.printTxData("stakingFactoryTx", stakingFactory.deployTransaction);
    // await data.printBalances();

    // await console.log("        --- Setup 2 - OGToken mint(...) permissioning ---");
    // const setup2 = [];
    // setup2.push(data.ogToken.setPermission(data.deployer, 1, true, ethers.utils.parseUnits("0", 18)));
    // setup2.push(data.ogToken.setPermission(stakingFactory.address, 1, true, ethers.utils.parseUnits("100", 18)));
    // setup2.push(data.ogdToken.setPermission(stakingFactory.address, 1, true, ethers.utils.parseUnits("123456", 18)));
    // setup2.push(data.ogdToken.setPermission(stakingFactory.address, 2, true, ethers.utils.parseUnits("123456", 18)));
    // const [setPermission1, setPermission2, setPermission3, setPermission4] = await Promise.all(setup2);
    // await data.printTxData("setPermission1", setPermission1);
    // await data.printTxData("setPermission2", setPermission2);
    // await data.printTxData("setPermission3", setPermission3);
    // await data.printTxData("setPermission4", setPermission4);
    // await data.printBalances();


    console.log("        --- Setup 2 - OGToken and OGDToken permissioning ---");
    const setup2 = [];
    setup2.push(ogToken.setPermission(data.deployer, ROLE.SETCONFIG, true, 0));
    setup2.push(ogToken.setPermission(data.deployer, ROLE.MINTTOKENS, true, ethers.utils.parseUnits("123456789", 18)));
    // setup2.push(ogToken.setPermission(stakingFactory.address, ROLE.SETPERMISSION, true, 0));
    // setup2.push(ogToken.setPermission(stakingFactory.address, ROLE.SETCONFIG, true, 0));
    setup2.push(ogToken.setPermission(stakingFactory.address, ROLE.MINTTOKENS, true, ethers.utils.parseUnits("123456789", 18)));
    setup2.push(ogToken.setPermission(stakingFactory.address, ROLE.BURNTOKENS, true, 0));
    setup2.push(ogdToken.setPermission(data.deployer, ROLE.SETCONFIG, true, 0));
    // setup2.push(ogdToken.setPermission(stakingFactory.address, ROLE.SETPERMISSION, true, 0));
    // setup2.push(ogdToken.setPermission(stakingFactory.address, ROLE.SETCONFIG, true, 0));
    setup2.push(ogdToken.setPermission(stakingFactory.address, ROLE.MINTTOKENS, true, ethers.utils.parseUnits("123456789", 18)));
    setup2.push(ogdToken.setPermission(stakingFactory.address, ROLE.BURNTOKENS, true, 0));
    const setup2Txs = await Promise.all(setup2);
    for (let j = 0; j < setup2Txs.length; j++) {
        await data.printTxData("setup2Txs[" + j + "]", setup2Txs[j]);
    }
    await data.printBalances();

    console.log("        --- Setup Completed ---");
    console.log("");
  });

  describe("TestStakingFactory - Workflow #0 - Stake, stake, stake, unstake, unstake", function() {
    it("Workflow #0 - Stake, stake, stake, unstake, unstake", async function() {
      console.log("        --- Test 1 - Mint 10,000 OG tokens for user{1..3}; user approve 100 FEE for OGToken to spend ---");
      const ogTokens = ethers.utils.parseUnits("10000", 18);
      const test1 = [];
      test1.push(data.ogToken.mint(data.user1, ogTokens));
      test1.push(data.ogToken.mint(data.user2, ogTokens));
      test1.push(data.ogToken.mint(data.user3, ogTokens));
      test1.push(data.ogToken.connect(data.user1Signer).approve(data.stakingFactory.address, ogTokens));
      test1.push(data.ogToken.connect(data.user2Signer).approve(data.stakingFactory.address, ogTokens));
      test1.push(data.ogToken.connect(data.user3Signer).approve(data.stakingFactory.address, ogTokens));
      const [mint1, mint2, mint3, approve1, approve2, approve3] = await Promise.all(test1);
      await data.printTxData("mint1", mint1);
      await data.printTxData("mint2", mint2);
      await data.printTxData("mint3", mint3);
      await data.printTxData("approve1", approve1);
      await data.printTxData("approve2", approve2);
      await data.printTxData("approve3", approve3);
      await data.printBalances();

      console.log("        --- Test 2 - Stake #1 - StakingFactory.addStakingForToken() ---");
      let ogTokensToStake = ethers.utils.parseUnits("1000", 18);
      let duration = 6;
      const test2 = [];
      test2.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake, duration, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake, duration, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake, duration, data.ogToken.address, "OGToken"));
      const [addStake1, addStake2, addStake3] = await Promise.all(test2);
      const stakingsLength = await data.stakingFactory.stakingsLength();
      const stakings = [];
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await data.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        stakings.push(staking);
        await data.addStakingData(staking);
      }
      await data.printTxData("addStake1", addStake1);
      await data.printTxData("addStake2", addStake2);
      await data.printTxData("addStake3", addStake3);
      await data.printBalances();

      console.log("        --- Test 3 - Stake #2 - StakingFactory.addStakingForToken() ---");
      data.pause("Waiting", duration);
      ogTokensToStake = ethers.utils.parseUnits("1000", 18);
      duration = 3;
      const test3 = [];
      test3.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake, duration, data.fee0Token.address, "FEE0Token"));
      test3.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake, duration, data.fee0Token.address, "FEE0Token"));
      test3.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake, duration, data.ogToken.address, "OGToken"));
      const [addStake4, addStake5, addStake6] = await Promise.all(test3);
      await data.printTxData("addStake4", addStake4);
      await data.printTxData("addStake5", addStake5);
      await data.printTxData("addStake6", addStake6);
      await data.printBalances();

      console.log("        --- Test 4 - Stake #3 - Staking.stake() ---");
      ogTokensToStake = ethers.utils.parseUnits("1000", 18);
      duration = 3;

      const test4a = [];
      test4a.push(data.ogToken.connect(data.user1Signer).approve(stakings[0].address, ogTokensToStake));
      test4a.push(data.ogToken.connect(data.user2Signer).approve(stakings[0].address, ogTokensToStake));
      test4a.push(data.ogToken.connect(data.user3Signer).approve(stakings[1].address, ogTokensToStake));
      const [approve4, approve5, approve6] = await Promise.all(test4a);
      await data.printTxData("approve4", approve4);
      await data.printTxData("approve5", approve5);
      await data.printTxData("approve6", approve6);
      const test4b = [];
      test4b.push(stakings[0].connect(data.user1Signer).stake(ogTokensToStake, duration));
      test4b.push(stakings[0].connect(data.user2Signer).stake(ogTokensToStake, duration));
      test4b.push(stakings[1].connect(data.user3Signer).stake(ogTokensToStake, duration));
      const [addStake7, addStake8, addStake9] = await Promise.all(test4b);
      await data.printTxData("addStake7", addStake7);
      await data.printTxData("addStake8", addStake8);
      await data.printTxData("addStake9", addStake9);
      await data.printBalances();

      console.log("        --- Test 5 - Unstake #1 - unstake(some) ---");
      data.pause("Waiting", duration);
      let ogTokensToUnstake = ethers.utils.parseUnits("2000", 18);
      const test5 = [];
      test5.push(stakings[0].connect(data.user1Signer).unstake(ogTokensToUnstake));
      test5.push(stakings[0].connect(data.user2Signer).unstake(ogTokensToUnstake));
      test5.push(stakings[1].connect(data.user3Signer).unstake(ogTokensToUnstake));
      const [unstake1, unstake2, unstake3] = await Promise.all(test5);
      await data.printTxData("unstake1", unstake1);
      await data.printTxData("unstake2", unstake2);
      await data.printTxData("unstake3", unstake3);
      await data.printBalances();

      console.log("        --- Test 6 - Unstake #2 - unstake(0 = remaining) ---");
      ogTokensToUnstake = ethers.utils.parseUnits("0", 18);
      const test6 = [];
      test6.push(stakings[0].connect(data.user1Signer).unstake(ogTokensToUnstake));
      test6.push(stakings[0].connect(data.user2Signer).unstake(ogTokensToUnstake));
      test6.push(stakings[1].connect(data.user3Signer).unstake(ogTokensToUnstake));
      const [unstake4, unstake5, unstake6] = await Promise.all(test6);
      await data.printTxData("unstake4", unstake4);
      await data.printTxData("unstake5", unstake5);
      await data.printTxData("unstake6", unstake6);
      await data.printBalances();
    });
  });

  describe("TestStakingFactory - Workflow #1 - Stake And Check weightedEnd", function() {
    it("Workflow #1 - Stake And Check weightedEnd", async function() {
      console.log("        --- Test 1 - Mint 10,000 OG tokens for user{1..3}; user approve 100 FEE for OGToken to spend ---");
      const ogTokens = ethers.utils.parseUnits("10000", 18);
      const test1 = [];
      test1.push(data.ogToken.mint(data.user1, ogTokens));
      test1.push(data.ogToken.mint(data.user2, ogTokens));
      test1.push(data.ogToken.mint(data.user3, ogTokens));
      test1.push(data.ogToken.connect(data.user1Signer).approve(data.stakingFactory.address, ogTokens));
      test1.push(data.ogToken.connect(data.user2Signer).approve(data.stakingFactory.address, ogTokens));
      test1.push(data.ogToken.connect(data.user3Signer).approve(data.stakingFactory.address, ogTokens));
      const [mint1, mint2, mint3, approve1, approve2, approve3] = await Promise.all(test1);
      await data.printTxData("mint1", mint1);
      await data.printTxData("mint2", mint2);
      await data.printTxData("mint3", mint3);
      await data.printTxData("approve1", approve1);
      await data.printTxData("approve2", approve2);
      await data.printTxData("approve3", approve3);
      await data.printBalances();

      console.log("        --- Test 2 - Stake #1 - StakingFactory.addStakingForToken() ---");
      let ogTokensToStake1 = ethers.utils.parseUnits("1000", 18);
      let ogTokensToStake2 = ethers.utils.parseUnits("2000", 18);
      let ogTokensToStake3 = ethers.utils.parseUnits("3000", 18);
      let duration1 = SECONDS_PER_DAY * 2;
      let duration2 = SECONDS_PER_DAY * 30;
      let duration3 = SECONDS_PER_YEAR;
      const test2 = [];
      test2.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake1, duration1, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake2, duration2, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake3, duration3, data.fee0Token.address, "FEE0Token"));
      const [addStake1, addStake2, addStake3] = await Promise.all(test2);
      const stakingsLength = await data.stakingFactory.stakingsLength();
      const stakings = [];
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await data.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        stakings.push(staking);
        await data.addStakingData(staking);
      }
      await data.printTxData("addStake1", addStake1);
      await data.printTxData("addStake2", addStake2);
      // await data.printTxData("addStake3", addStake3);
      await data.printBalances();

      const block = await ethers.provider.getBlock("latest");
      const now = block.timestamp;
      const expectedDurationDenominator = ogTokensToStake1.add(ogTokensToStake2).add(ogTokensToStake3);
      const expectedDuration = expectedDurationDenominator.gt(0) ? ogTokensToStake1.mul(duration1).add(ogTokensToStake2.mul(duration2)).add(ogTokensToStake3.mul(duration3)).div(expectedDurationDenominator) : 0;
      const expectedWeightedEnd = expectedDuration.add(parseInt(new Date()/1000));
      console.log("        expectedWeightedEnd: " + data.termString(parseInt(expectedWeightedEnd.toString())-now) + " " + expectedWeightedEnd + " +/- 150");
      const weightedEnd = await stakings[0].weightedEnd();
      console.log("        weightedEnd        : " + data.termString(parseInt(weightedEnd.toString())-now) + " " + weightedEnd);
      expect(parseFloat(weightedEnd.toString())).to.be.closeTo(parseFloat(expectedWeightedEnd.toString()), 150, "weightedEnd seems off");
    });
  });

  describe("TestStakingFactory - Workflow #2 - Stake with expected exception", function() {
    it("Workflow #2 - Stake with expected exception", async function() {
      console.log("        --- Test 1 - Mint 10,000 OG tokens for user{1..3}; user approve 100 FEE for OGToken to spend ---");
      const ogTokens = ethers.utils.parseUnits("10000", 18);
      const test1 = [];
      test1.push(data.ogToken.mint(data.user1, ogTokens));
      test1.push(data.ogToken.mint(data.user2, ogTokens));
      test1.push(data.ogToken.mint(data.user3, ogTokens));
      test1.push(data.ogToken.connect(data.user1Signer).approve(data.stakingFactory.address, ogTokens));
      test1.push(data.ogToken.connect(data.user2Signer).approve(data.stakingFactory.address, ogTokens));
      test1.push(data.ogToken.connect(data.user3Signer).approve(data.stakingFactory.address, ogTokens));
      const [mint1, mint2, mint3, approve1, approve2, approve3] = await Promise.all(test1);
      await data.printTxData("mint1", mint1);
      await data.printTxData("mint2", mint2);
      await data.printTxData("mint3", mint3);
      await data.printTxData("approve1", approve1);
      await data.printTxData("approve2", approve2);
      await data.printTxData("approve3", approve3);
      await data.printBalances();

      console.log("        --- Test 2 - Stake #1 - StakingFactory.addStakingForToken() ---");
      let ogTokensToStake1 = ethers.utils.parseUnits("1000", 18);
      let ogTokensToStake2 = ethers.utils.parseUnits("2000", 18);
      let ogTokensToStake3 = ogTokens.add(ethers.utils.parseUnits("1", 18));
      let duration1 = 1000;
      let duration2 = 10000;
      let duration3 = 100000;
      const test2 = [];
      test2.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake1, duration1, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake2, duration2, data.fee0Token.address, "FEE0Token"));
      // test2.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake3, duration3, data.fee0Token.address, "FEE0Token"));
      const [addStake1, addStake2/*, addStake3*/] = await Promise.all(test2);
      await data.expectException("Insufficient approved OG tokens to stake with", "revert", data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake3, duration3, data.fee0Token.address, "FEE0Token"));

      const stakingsLength = await data.stakingFactory.stakingsLength();
      const stakings = [];
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await data.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        stakings.push(staking);
        await data.addStakingData(staking);
      }
      await data.printTxData("addStake1", addStake1);
      await data.printTxData("addStake2", addStake2);
      // await data.printTxData("addStake3", addStake3);
      await data.printBalances();
    });
  });

  describe("TestStakingFactory - Workflow #3 - Stake, slash and unstake", function() {
    it("Workflow #3 - Stake, slash and unstake", async function() {
      console.log("        --- Test 1 - Mint 10,000 OG tokens for user{1..3}; user{1..3} approve 10,000 FEE for StakingFactory to spend ---");
      const ogTokens = ethers.utils.parseUnits("10000", 18);
      const test1 = [];
      test1.push(data.ogToken.mint(data.user1, ogTokens));
      test1.push(data.ogToken.mint(data.user2, ogTokens));
      test1.push(data.ogToken.mint(data.user3, ogTokens));
      test1.push(data.ogToken.connect(data.user1Signer).approve(data.stakingFactory.address, ogTokens));
      test1.push(data.ogToken.connect(data.user2Signer).approve(data.stakingFactory.address, ogTokens));
      test1.push(data.ogToken.connect(data.user3Signer).approve(data.stakingFactory.address, ogTokens));
      const [mint1, mint2, mint3, approve1, approve2, approve3] = await Promise.all(test1);
      await data.printTxData("mint1", mint1);
      await data.printTxData("mint2", mint2);
      await data.printTxData("mint3", mint3);
      await data.printTxData("approve1", approve1);
      await data.printTxData("approve2", approve2);
      await data.printTxData("approve3", approve3);
      await data.printBalances();

      console.log("        --- Test 2 - user{1..3} -> StakingFactory.addStakingForToken(1,000, duration) ---");
      let ogTokensToStake = ethers.utils.parseUnits("1000", 18);
      let duration = 3;
      const test2 = [];
      test2.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake, duration, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake, duration, data.fee0Token.address, "FEE0Token"));
      test2.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake, duration, data.fee0Token.address, "FEE0Token"));
      const [addStake1, addStake2, addStake3] = await Promise.all(test2);
      const stakingsLength = await data.stakingFactory.stakingsLength();
      const stakings = [];
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await data.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        stakings.push(staking);
        await data.addStakingData(staking);
      }
      await data.printTxData("addStake1", addStake1);
      await data.printTxData("addStake2", addStake2);
      await data.printTxData("addStake3", addStake3);
      await data.printBalances();

      console.log("        --- Test 3 - deployer -> StakingFactory.slash(staking, 30%) ---");
      let slashingFactor = ethers.utils.parseUnits("3", 17); // 30%
      const test3 = [];
      test3.push(data.stakingFactory.slash(stakings[0].address, slashingFactor));
      const [slash1] = await Promise.all(test3);
      await data.printTxData("slash1", slash1);
      await data.printBalances();

      console.log("        --- Test 4 - user{1..3} -> unstake(1,000) ---");
      ogTokensToUnstake = ethers.utils.parseUnits("1000", 18);
      const test4 = [];
      test4.push(stakings[0].connect(data.user1Signer).unstake(ogTokensToUnstake));
      test4.push(stakings[0].connect(data.user2Signer).unstake(ogTokensToUnstake));
      test4.push(stakings[0].connect(data.user3Signer).unstake(ogTokensToUnstake));
      const [unstake1, unstake2, unstake3] = await Promise.all(test4);
      await data.printTxData("unstake1", unstake1);
      await data.printTxData("unstake2", unstake2);
      await data.printTxData("unstake3", unstake3);
      await data.printBalances();
    });
  });

  describe("TestStakingFactory - Workflow #3 - Stake through factory, stake, restake, unstake(some), stakeAll(0 = remaining)", function() {
    it("Stake through factory, stake, restake, unstake(some), unstakeAll(0 = remaining)", async function() {
      console.log("        --- Test 1 - Mint 10,000 OG tokens for user1; user1 approve 10,000 FEE for StakingFactory to spend ---");
      const ogTokens = ethers.utils.parseUnits("10000", 18);
      const test1 = [];
      test1.push(data.ogToken.mint(data.user1, ogTokens));
      test1.push(data.ogToken.connect(data.user1Signer).approve(data.stakingFactory.address, ogTokens));
      const [mint1, approve1] = await Promise.all(test1);
      await data.printTxData("mint1", mint1);
      await data.printTxData("approve1", approve1);
      await data.printBalances();

      console.log("        --- Test 2 - user1 -> StakingFactory.addStakingForToken(1,000, duration) ---");
      let ogTokensToStake = ethers.utils.parseUnits("1000", 18);
      let duration = 2;
      const test2 = [];
      test2.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake, duration, data.fee0Token.address, "FEE0Token"));
      const [addStake1] = await Promise.all(test2);
      const stakingsLength = await data.stakingFactory.stakingsLength();
      const stakings = [];
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await data.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        stakings.push(staking);
        await data.addStakingData(staking);
      }
      await data.printTxData("addStake1", addStake1);
      await data.printBalances();

      console.log("        ---  Test 3 - user1 -> OGToken.approve(stakeAddress, 1,000) and user1 -> Staking.stake(1,000, duration)---");
      duration = 3;
      const test3a = [];
      test3a.push(data.ogToken.connect(data.user1Signer).approve(stakings[0].address, ogTokensToStake));
      const [approve2] = await Promise.all(test3a);
      const test3b = [];
      test3b.push(stakings[0].connect(data.user1Signer).stake(ogTokensToStake, duration));
      const [addStake2] = await Promise.all(test3b);
      await data.printTxData("approve2", approve2);
      await data.printTxData("addStake2", addStake2);
      await data.printBalances();

      // console.log("        --- Test 4 - user1 -> restake(4) ---");
      // duration = 4;
      // const test4 = [];
      // test4.push(stakings[0].connect(data.user1Signer).restake(duration));
      // const [restake1] = await Promise.all(test4);
      // await data.printTxData("restake1", restake1);
      // await data.printBalances();
      //
      // console.log("        --- Test 5 - user1 -> unstake(1,000) ---");
      // let ogTokensToUnstake = ethers.utils.parseUnits("1000", 18);
      // data.pause("Waiting", duration + 1);
      // await data.printBalances();
      // const test5 = [];
      // test5.push(stakings[0].connect(data.user1Signer).unstake(ogTokensToUnstake));
      // const [unstake1] = await Promise.all(test5);
      // await data.printTxData("unstake1", unstake1);
      // await data.printBalances();

      console.log("        --- Test 6 - user1 -> unstake(0 = remaining) ---");
      data.pause("Waiting", duration + 1);
      await data.printBalances();
      const test6 = [];
      test6.push(stakings[0].connect(data.user1Signer).unstake(0));
      const [unstake5] = await Promise.all(test6);
      await data.printTxData("unstake5", unstake5);
      await data.printBalances();
    });
  });

  // describe("TestStakingFactory - Workflow #4 - Stake, and test transfers", function() {
  //   it("Workflow #4 - Stake, and test transfers", async function() {
  //     console.log("        --- Test 1 - Mint 10,000 OG tokens for user{1..3}; user{1..3} approve 10,000 FEE for StakingFactory to spend ---");
  //     const ogTokens = ethers.utils.parseUnits("10000", 18);
  //     const test1 = [];
  //     test1.push(data.ogToken.mint(data.user1, ogTokens));
  //     // test1.push(data.ogToken.mint(data.user2, ogTokens));
  //     // test1.push(data.ogToken.mint(data.user3, ogTokens));
  //     test1.push(data.ogToken.connect(data.user1Signer).approve(data.stakingFactory.address, ogTokens));
  //     // test1.push(data.ogToken.connect(data.user2Signer).approve(data.stakingFactory.address, ogTokens));
  //     // test1.push(data.ogToken.connect(data.user3Signer).approve(data.stakingFactory.address, ogTokens));
  //     const [mint1/*, mint2, mint3*/, approve1/*, approve2, approve3*/] = await Promise.all(test1);
  //     await data.printTxData("mint1", mint1);
  //     // await data.printTxData("mint2", mint2);
  //     // await data.printTxData("mint3", mint3);
  //     await data.printTxData("approve1", approve1);
  //     // await data.printTxData("approve2", approve2);
  //     // await data.printTxData("approve3", approve3);
  //     await data.printBalances();
  //
  //     console.log("        --- Test 2 - user1 -> StakingFactory.addStakingForToken(1,000, duration) ---");
  //     let ogTokensToStake = ethers.utils.parseUnits("1000", 18);
  //     let duration = 2;
  //     const test2 = [];
  //     test2.push(data.stakingFactory.connect(data.user1Signer).addStakingForToken(ogTokensToStake, duration, data.fee0Token.address, "FEE0Token"));
  //     // test2.push(data.stakingFactory.connect(data.user2Signer).addStakingForToken(ogTokensToStake, duration, data.fee0Token.address, "FEE0Token"));
  //     // test2.push(data.stakingFactory.connect(data.user3Signer).addStakingForToken(ogTokensToStake, duration, data.fee0Token.address, "FEE0Token"));
  //     const [addStake1/*, addStake2, addStake3*/] = await Promise.all(test2);
  //     const stakingsLength = await data.stakingFactory.stakingsLength();
  //     const stakings = [];
  //     for (let j = 0; j < stakingsLength; j++) {
  //       const stakingAddress = await data.stakingFactory.getStakingByIndex(j);
  //       const staking = Staking.attach(stakingAddress[1]);
  //       stakings.push(staking);
  //       await data.addStakingData(staking);
  //     }
  //     await data.printTxData("addStake1", addStake1);
  //     // await data.printTxData("addStake2", addStake2);
  //     // await data.printTxData("addStake3", addStake3);
  //     await data.printBalances();
  //
  //     // console.log("        --- Test 3 - OGS transferX locked during staking period ---");
  //     // const test3 = [];
  //     // test3.push(stakings[0].connect(data.user2Signer).approve(data.user3, ethers.utils.parseUnits("1000", 18)));
  //     // const [approve4] = await Promise.all(test3);
  //     // await data.printTxData("approve4", approve4);
  //     // await data.expectException("OGS transfer locked", "Stake period not ended", stakings[0].connect(data.user1Signer).transfer(data.user4, ethers.utils.parseUnits("1.111111111111111111", 18)));
  //     // await data.expectException("OGS transferFrom locked", "Stake period not ended", stakings[0].connect(data.user3Signer).transferFrom(data.user2, data.user4, ethers.utils.parseUnits("2.222222222222222222", 18)));
  //
  //     console.log("        --- Test 4 - OGS transferX unlocked after staking period ---");
  //     data.pause("Waiting", duration + 1);
  //     const test4 = [];
  //     test4.push(stakings[0].connect(data.user1Signer).transfer(data.user4, ogTokensToStake.dividedBy(2)));
  //     // test4.push(stakings[0].connect(data.user1Signer).transfer(data.user4, ethers.utils.parseUnits("1.111111111111111111", 18)));
  //     // test4.push(stakings[0].connect(data.user3Signer).transferFrom(data.user2, data.user4, ethers.utils.parseUnits("2.222222222222222222", 18)));
  //     const [transfer1/*, transferFrom1*/] = await Promise.all(test4);
  //     await data.printTxData("transfer1", transfer1);
  //     // await data.printTxData("transferFrom1", transferFrom1);
  //     await data.printBalances();
  //   });
  // });
});
