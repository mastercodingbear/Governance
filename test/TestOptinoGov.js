const { ZERO_ADDRESS, SECONDS_PER_DAY, SECONDS_PER_YEAR, ROLE, Data } = require('./helpers/common');
const { expect } = require("chai");
const { BigNumber, _TypedDataEncoder } = require("ethers");
const util = require('util');

let SimpleCurve;
let OGToken;
let OGDToken;
let TestToken;
let OptinoGov;
let data;
const verbose = false;

describe("TestOptinoGov", function() {
  beforeEach("Setup", async function() {
    OGToken = await ethers.getContractFactory("OGToken");
    OGDToken = await ethers.getContractFactory("OGDToken");
    SimpleCurve = await ethers.getContractFactory("SimpleCurve");
    TestToken = await ethers.getContractFactory("TestToken");
    OptinoGov = await ethers.getContractFactory("OptinoGov");
    data = new Data();
    await data.init();

    console.log("        --- Setup 1 - Deploy OGToken, OGDToken, FEE0, then OptinoGov ---");
    const setup1a = [];
    const mintOGTokens = ethers.utils.parseUnits("40000", 18);
    const mintFee0Tokens = ethers.utils.parseUnits("100", 18);
    let ogRewardTerms = [SECONDS_PER_DAY, SECONDS_PER_YEAR, 2 * SECONDS_PER_YEAR];
    let ogRewardRates = [BigNumber.from(SECONDS_PER_YEAR).mul(BigNumber.from(10).pow(10)), BigNumber.from(2 * SECONDS_PER_YEAR).mul(BigNumber.from(10).pow(10)), BigNumber.from(3 * SECONDS_PER_YEAR).mul(BigNumber.from(10).pow(10))];
    let voteWeightTerms = [SECONDS_PER_DAY, 3 * SECONDS_PER_YEAR];
    let voteWeightRates = [BigNumber.from("1").mul(BigNumber.from(10).pow(16)), BigNumber.from("365").mul(3).mul(BigNumber.from(10).pow(16))];
    setup1a.push(OGToken.deploy("OG", "Optino Governance", 18, data.deployer, mintOGTokens));
    setup1a.push(OGDToken.deploy("OGD", "Optino Governance Dividend", 18, data.deployer, ethers.utils.parseUnits("0", 18)));
    setup1a.push(SimpleCurve.deploy(ogRewardTerms, ogRewardRates));
    setup1a.push(SimpleCurve.deploy(voteWeightTerms, voteWeightRates));
    setup1a.push(TestToken.deploy("FEE0", "Fee0", 18, data.deployer, mintFee0Tokens));
    const [ogToken, ogdToken, ogRewardCurve, voteWeightCurve, fee0Token] = await Promise.all(setup1a);
    const setup1b = [];
    const optinoGov = await OptinoGov.deploy(ogToken.address, ogdToken.address, ogRewardCurve.address, voteWeightCurve.address);
    await data.setOptinoGovData(ogToken, ogdToken, ogRewardCurve, voteWeightCurve, optinoGov, fee0Token);
    await data.printTxData("ogToken.deployTransaction", ogToken.deployTransaction);
    await data.printTxData("ogdToken.deployTransaction", ogdToken.deployTransaction);
    await data.printTxData("ogRewardCurve.deployTransaction", ogRewardCurve.deployTransaction);
    await data.printTxData("voteWeightCurve.deployTransaction", voteWeightCurve.deployTransaction);
    await data.printTxData("fee0Token.deployTransaction", fee0Token.deployTransaction);
    await data.printTxData("optinoGov.deployTransaction", optinoGov.deployTransaction);
    console.log("        OptinoGov.bytecode.length/2: " + OptinoGov.bytecode.length/2);
    // if (verbose) {
    //   await data.printBalances();
    // }

    console.log("        --- Setup 2 - OGToken and OGDToken permissioning ---");
    const setup2 = [];
    setup2.push(ogToken.setPermission(data.deployer, ROLE.SETCONFIG, true, 0));
    setup2.push(ogToken.setPermission(data.optinoGov.address, ROLE.SETPERMISSION, true, 0));
    setup2.push(ogToken.setPermission(data.optinoGov.address, ROLE.SETCONFIG, true, 0));
    setup2.push(ogToken.setPermission(data.optinoGov.address, ROLE.MINTTOKENS, true, ethers.utils.parseUnits("123456789", 18)));
    setup2.push(ogToken.setPermission(data.optinoGov.address, ROLE.BURNTOKENS, true, 0));
    setup2.push(ogdToken.setPermission(data.deployer, ROLE.SETCONFIG, true, 0));
    setup2.push(ogdToken.setPermission(data.optinoGov.address, ROLE.SETPERMISSION, true, 0));
    setup2.push(ogdToken.setPermission(data.optinoGov.address, ROLE.SETCONFIG, true, 0));
    setup2.push(ogdToken.setPermission(data.optinoGov.address, ROLE.MINTTOKENS, true, ethers.utils.parseUnits("123456789", 18)));
    setup2.push(ogdToken.setPermission(data.optinoGov.address, ROLE.BURNTOKENS, true, 0));
    const setup2Txs = await Promise.all(setup2);
    for (let j = 0; j < setup2Txs.length; j++) {
        await data.printTxData("setup2Txs[" + j + "]", setup2Txs[j]);
    }
    // await data.printBalances();

    console.log("        --- Setup 3 - OGDToken.addDividendToken([ETH, FEE0]) ---");
    const setup3 = [];
    setup3.push(data.ogdToken.addDividendToken(ZERO_ADDRESS));
    setup3.push(data.ogdToken.addDividendToken(fee0Token.address));
    const [addDividendToken0, addDividendToken1] = await Promise.all(setup3);
    await data.printTxData("addDividendToken0", addDividendToken0);
    await data.printTxData("addDividendToken1", addDividendToken1);
    // await data.printBalances();

    console.log("        --- Setup 4 - Remove deployer permissions from OGToken and OGDToken ---");
    const setup4 = [];
    setup4.push(ogToken.setPermission(data.deployer, ROLE.SETCONFIG, false, 0));
    setup4.push(ogToken.setPermission(data.deployer, ROLE.SETPERMISSION, false, 0));
    setup4.push(ogdToken.setPermission(data.deployer, ROLE.SETCONFIG, false, 0));
    setup4.push(ogdToken.setPermission(data.deployer, ROLE.SETPERMISSION, false, 0));
    const setup4Txs = await Promise.all(setup4);
    for (let j = 0; j < setup4Txs.length; j++) {
        await data.printTxData("setup4Txs[" + j + "]", setup4Txs[j]);
    }
    // await data.printBalances();

    console.log("        --- Setup 5 - Transfer OGTokens, user{1..3} approve 2,000 OGTokens to OptinoGov, deployer approve 2,000 FEE0 tokens to OGDToken ---");
    const ogTokens = ethers.utils.parseUnits("10000", 18);
    const approveTokens = ethers.utils.parseUnits("2000", 18);
    const setup5 = [];
    setup5.push(ogToken.transfer(data.user1, ogTokens));
    setup5.push(ogToken.transfer(data.user2, ogTokens));
    setup5.push(ogToken.transfer(data.user3, ogTokens));
    setup5.push(ogToken.connect(data.user1Signer).approve(data.optinoGov.address, approveTokens));
    setup5.push(ogToken.connect(data.user2Signer).approve(data.optinoGov.address, approveTokens));
    setup5.push(ogToken.connect(data.user3Signer).approve(data.optinoGov.address, approveTokens));
    setup5.push(fee0Token.approve(data.ogdToken.address, approveTokens));
    const [transfer1, transfer2, transfer3, approve1, approve2, approve3, approve4] = await Promise.all(setup5);
    await data.printTxData("transfer1", transfer1);
    await data.printTxData("transfer2", transfer2);
    await data.printTxData("transfer3", transfer3);
    await data.printTxData("approve1", approve1);
    await data.printTxData("approve2", approve2);
    await data.printTxData("approve3", approve3);
    await data.printTxData("approve4", approve4);
    await data.printBalances();

    console.log("        --- Setup Completed ---");
    console.log("");
  });

  describe("TestOptinoGov - Workflow #0", function() {
    it("Workflow #0", async function() {
      console.log("        --- Test 1 - user{1..3} commit OGTokens for {5, 50, 500} seconds duration ---");
      const tokensToCommit = ethers.utils.parseUnits("1000", 18);
      const test1 = [];
      test1.push(data.optinoGov.connect(data.user1Signer).commit(tokensToCommit, 5));
      test1.push(data.optinoGov.connect(data.user2Signer).commit(tokensToCommit, 50));
      test1.push(data.optinoGov.connect(data.user3Signer).commit(tokensToCommit, 500));
      const [commit1, commit2, commit3] = await Promise.all(test1);
      await data.printTxData("commit1", commit1);
      await data.printTxData("commit2", commit2);
      await data.printTxData("commit3", commit3);
      await data.printBalances();

      console.log("        --- Test 2 - user{1,2} delegate to user3---");
      const test2 = [];
      test2.push(data.optinoGov.connect(data.user1Signer).delegate(data.user3));
      test2.push(data.optinoGov.connect(data.user2Signer).delegate(data.user3));
      const [delegate1, delegate2] = await Promise.all(test2);
      await data.printTxData("delegate1", delegate1);
      await data.printTxData("delegate2", delegate2);
      await data.printBalances();

      console.log("        --- Test 3 - user{2} commit again for {55} seconds duration ---");
      const test3 = [];
      test3.push(data.optinoGov.connect(data.user2Signer).commit(tokensToCommit, 55));
      const [commit4] = await Promise.all(test3);
      await data.printTxData("commit4", commit4);
      await data.printBalances();

      console.log("        --- Test 4 - user{1..2} collecting rewards, user3 collecting and committing rewards and extending duration to 1d ---");
      const test4 = [];
      test4.push(data.optinoGov.connect(data.user1Signer).commit(0, 0));
      test4.push(data.optinoGov.connect(data.user2Signer).commit(0, 0));
      test4.push(data.optinoGov.connect(data.user3Signer).commit(0, SECONDS_PER_DAY));
      const [collectReward1, collectReward2, collectReward3] = await Promise.all(test4);
      await data.printTxData("collectReward1", collectReward1);
      await data.printTxData("collectReward2", collectReward2);
      await data.printTxData("collectReward3", collectReward3);
      await data.printBalances();

      await console.log("        --- Test 5 - deployer uncommitFor(user1) for a % fee ---");
      data.pause("Waiting", 5);
      const test5 = [];
      test5.push(data.optinoGov.uncommitFor(data.user1));
      const [uncommitFor1] = await Promise.all(test5);
      await data.printTxData("uncommitFor1", uncommitFor1);
      await data.printBalances();

      console.log("        --- Test 6 - deployer deposits dividends of 10 ETH and 100 FEE ---");
      const depositFee1Tokens = ethers.utils.parseUnits("10", 18);
      const depositFee2Tokens = ethers.utils.parseUnits("100", 18);
      const test6 = [];
      test6.push(data.ogdToken.depositDividend(ZERO_ADDRESS, depositFee1Tokens, { value: depositFee1Tokens }));
      test6.push(data.ogdToken.depositDividend(data.fee0Token.address, depositFee2Tokens));
      const [depositDividendFee1, depositDividendFee2] = await Promise.all(test6);
      await data.printTxData("depositDividendFee1", depositDividendFee1);
      await data.printTxData("depositDividendFee2", depositDividendFee2);
      await data.printBalances();

      console.log("        --- Test 7 - user{1..3} withdraw ETH and FEE dividends ---");
      const test7 = [];
      test7.push(data.ogdToken.connect(data.user1Signer).withdrawDividends());
      test7.push(data.ogdToken.connect(data.user2Signer).withdrawDividends());
      test7.push(data.ogdToken.connect(data.user3Signer).withdrawDividends());
      const [withdrawDividends1, withdrawDividends2, withdrawDividends3] = await Promise.all(test7);
      await data.printTxData("withdrawDividends1", withdrawDividends1);
      await data.printTxData("withdrawDividends2", withdrawDividends2);
      await data.printTxData("withdrawDividends3", withdrawDividends3);
      await data.printBalances();

      console.log("        --- Test Completed ---");
      console.log("");

      // const user1Fee1Balance = await fee1Token.balanceOf(data.user1);
      // console.log("user1Fee1Balance: " + user1Fee1Balance);
      // expect(ethers.utils.parseUnits(user1Fee1Balance.toString())).to.equal(ethers.utils.parseUnits("333.333333333333333333", 18));
    });
  });

  describe("TestOptinoGov - Workflow #1", function() {
    it("Workflow #1", async function() {
      console.log("        --- Test 1 - user{1..3} commit OGTokens for {1, 1, 1} seconds duration ---");
      const tokensToCommit = ethers.utils.parseUnits("1000", 18);
      const test1 = [];
      test1.push(data.optinoGov.connect(data.user1Signer).commit(tokensToCommit, 1));
      test1.push(data.optinoGov.connect(data.user2Signer).commit(tokensToCommit, 1));
      test1.push(data.optinoGov.connect(data.user3Signer).commit(tokensToCommit, 1));
      const [commit1, commit2, commit3] = await Promise.all(test1);
      await data.printTxData("commit1", commit1);
      await data.printTxData("commit2", commit2);
      await data.printTxData("commit3", commit3);
      await data.printBalances();

      console.log("        --- Test 2 - user{1..3} approve 2,000 OGDTokens to OptinoGov ---");
      const approveTokens = ethers.utils.parseUnits("2000", 18);
      const test2 = [];
      test2.push(data.ogdToken.connect(data.user1Signer).approve(data.optinoGov.address, approveTokens));
      test2.push(data.ogdToken.connect(data.user2Signer).approve(data.optinoGov.address, approveTokens));
      test2.push(data.ogdToken.connect(data.user3Signer).approve(data.optinoGov.address, approveTokens));
      test2.push(data.fee0Token.approve(data.ogdToken.address, approveTokens));
      const [approve1, approve2, approve3, approve4] = await Promise.all(test2);
      await data.printTxData("approve1", approve1);
      await data.printTxData("approve2", approve2);
      await data.printTxData("approve3", approve3);
      await data.printTxData("approve3", approve4);
      await data.printBalances();

      console.log("        --- Test 3 - deployer deposits dividends of 10 ETH and 100 FEE ---");
      const depositFee1Tokens = ethers.utils.parseUnits("10", 18);
      const depositFee2Tokens = ethers.utils.parseUnits("100", 18);
      const test3 = [];
      test3.push(data.ogdToken.depositDividend(ZERO_ADDRESS, depositFee1Tokens, { value: depositFee1Tokens }));
      test3.push(data.ogdToken.depositDividend(data.fee0Token.address, depositFee2Tokens));
      const [depositDividendFee1, depositDividendFee2] = await Promise.all(test3);
      await data.printTxData("depositDividendFee1", depositDividendFee1);
      await data.printTxData("depositDividendFee2", depositDividendFee2);
      await data.printBalances();

      // console.log("        --- Test 4 - user2 transfer all to user3 ---");
      // const test4 = [];
      // test4.push(data.ogdToken.connect(data.user2Signer).transfer(data.user3, tokensToCommit));
      // const [transfer1] = await Promise.all(test4);
      // await data.printTxData("transfer1", transfer1);
      // await data.printBalances();
      //
      // console.log("        --- Test 5 - user{1..3} withdraw ETH and FEE dividends ---");
      // const test5 = [];
      // test5.push(data.ogdToken.connect(data.user1Signer).withdrawDividends());
      // test5.push(data.ogdToken.connect(data.user2Signer).withdrawDividends());
      // test5.push(data.ogdToken.connect(data.user3Signer).withdrawDividends());
      // const [withdrawDividends1, withdrawDividends2, withdrawDividends3] = await Promise.all(test5);
      // await data.printTxData("withdrawDividends1", withdrawDividends1);
      // await data.printTxData("withdrawDividends2", withdrawDividends2);
      // await data.printTxData("withdrawDividends3", withdrawDividends3);
      // await data.printBalances();

      console.log("        --- Test 4 - user{1..3} uncommit OGTokens ---");
      const tokensToUncommit = ethers.utils.parseUnits("100", 18);
      const test4 = [];
      // data.pause("Waiting", 5);
      test4.push(data.optinoGov.connect(data.user1Signer).uncommit(tokensToUncommit));
      test4.push(data.optinoGov.connect(data.user2Signer).uncommit(tokensToUncommit));
      test4.push(data.optinoGov.connect(data.user3Signer).uncommit(tokensToUncommit));
      const [uncommit1, uncommit2, uncommit3] = await Promise.all(test4);
      await data.printTxData("uncommit1", uncommit1);
      await data.printTxData("uncommit2", uncommit2);
      await data.printTxData("uncommit3", uncommit3);
      await data.printBalances();

      console.log("        --- Test Completed ---");
      console.log("");
    });
  });

  describe("TestOptinoGov - Workflow #2 - Developing", function() {
    it("Workflow #2 - Developing", async function() {
      console.log("        --- Test 1 - user{1..3} commit 1,000 OGTokens for x seconds, user3 delegate to user1 ---");
      let duration1 = 2;
      let tokensToCommit = ethers.utils.parseUnits("1000", 18);
      const test1 = [];
      test1.push(data.optinoGov.connect(data.user1Signer).commit(tokensToCommit, duration1 /*SECONDS_PER_DAY * 30*/));
      test1.push(data.optinoGov.connect(data.user2Signer).commit(tokensToCommit, duration1 /*SECONDS_PER_YEAR*/));
      test1.push(data.optinoGov.connect(data.user3Signer).commit(tokensToCommit, duration1 /*SECONDS_PER_YEAR * 3 / 2*/));
      const [commit1, commit2, commit3] = await Promise.all(test1);
      const delegate1 = await data.optinoGov.connect(data.user3Signer).delegate(data.user1);
      await data.printTxData("commit1", commit1);
      await data.printTxData("commit2", commit2);
      await data.printTxData("commit3", commit3);
      await data.printTxData("delegate1", delegate1);
      await data.printBalances();

      // console.log("        --- Test 4 - user1 propose(OGToken.mint(user{2,3}, 888.888)) ---");
      // var mintFunctionSig = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("mint(address,uint256)")).substring(0,10);
      // var description = "Proposal 0 - OGToken.mint(user{2,3}, 888.888)";
      // var mintTokens = ethers.utils.parseUnits("888.888", 18);
      // var targets = [data.ogToken.address, data.ogToken.address];
      // var values = [0, 0];
      // var bytes0 = '0x' + mintFunctionSig.substring(2) + data.addressToHex64(data.user2) + data.uint256ToHex64(mintTokens);
      // var bytes1 = '0x' + mintFunctionSig.substring(2) + data.addressToHex64(data.user3) + data.uint256ToHex64(mintTokens);
      // const dataItems = [bytes0, bytes1];
      // console.log("        mintFunctionSig: " + mintFunctionSig);
      // console.log("        description    : " + description);
      // console.log("        targets        : " + JSON.stringify(targets));
      // console.log("        values         : " + JSON.stringify(values));
      // console.log("        dataItems      : " + JSON.stringify(dataItems));
      // const propose1 = await data.optinoGov.connect(data.user1Signer).propose(description, targets, values, dataItems);
      // await data.printTxData("propose1", propose1);
      // await data.printBalances();

      console.log("        --- Test 2 - user1 propose(OGToken.setCap(888888888.888, true)) ---");
      var setCapFunctionSig = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("setCap(uint256,bool)")).substring(0,10);
      var description = "Proposal 0 - OGToken.setCap(888888888.888, true)";
      var capTokens = ethers.utils.parseUnits("888888888.888", 18);
      var targets = [data.ogToken.address];
      var values = [0];
      var bytes0 = '0x' + setCapFunctionSig.substring(2) + data.uint256ToHex64(capTokens) + data.uint256ToHex64(0);
      const dataItems = [bytes0];
      console.log("        setCapFunctionSig: " + setCapFunctionSig);
      console.log("        description      : " + description);
      console.log("        targets          : " + JSON.stringify(targets));
      console.log("        values           : " + JSON.stringify(values));
      console.log("        dataItems        : " + JSON.stringify(dataItems));
      const propose1 = await data.optinoGov.connect(data.user1Signer).propose(description, targets, values, dataItems);
      await data.printTxData("propose1", propose1);
      await data.printBalances();

      console.log("        --- Test 3 - voteBySigs ---");
      let privateKey = '0x9f9752b9387aa98f6b6ef115a34be9941264876381692b24b85fdd015d660124';
      let wallet = new ethers.Wallet(privateKey);
      const domain = {
          name: 'OptinoGov',
          chainId: 31337,
          verifyingContract: '0x7305816b5991eb8B06Ba62F9F48531410c4Cd610'
      }
      const types = {
          Vote: [
              { name: 'id', type: 'uint256' },
              { name: 'support', type: 'bool' },
          ],
      }
      const value = {
          id: 0,
          support: false,
      }
      const signature = await wallet._signTypedData(domain, types, value);
      console.log("        signature : " + signature);
      const voteBySigs1 = await data.optinoGov.connect(data.deployerSigner).voteBySigs(0, [signature]);
      await data.printTxData("voteBySigs1", voteBySigs1);
      await data.printBalances();


      // console.log("        --- Test 3 - user{1,2} vote ---");
      // const test3 = [];
      // test3.push(data.optinoGov.connect(data.user1Signer).vote(0, true));
      // test3.push(data.optinoGov.connect(data.user2Signer).vote(0, true));
      // // test3.push(data.optinoGov.connect(data.user3Signer).vote(0, true));
      // const [vote1, vote2/*, vote3*/] = await Promise.all(test3);
      // await data.printTxData("vote1", vote1);
      // await data.printTxData("vote2", vote2);
      // // await data.printTxData("vote3", vote3);
      // await data.printBalances();

      // console.log("        --- Test 4 - user1 execute(0) ---");
      // const execute1 = await data.optinoGov.connect(data.user1Signer).execute(0);
      // await data.printTxData("execute1", execute1);
      // await data.printBalances();

      console.log("        --- Test Completed ---");
      console.log("");
    });
  });
});
