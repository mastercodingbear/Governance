const { expect, assert } = require("chai");
const { BigNumber } = require("ethers");
const util = require('util');

describe("TestSimpleCurve", function() {
  it("TestSimpleCurve - #0", async function() {

    function printEvents(contract, receipt) {
      receipt.logs.forEach((log) => {
        var data = contract.interface.parseLog(log);
        var result = data.name + "(";
        let separator = "";
        data.eventFragment.inputs.forEach((a) => {
          result = result + separator + a.name + ": ";
          result = result + data.args[a.name].toString();
          separator = ", ";
        });
        result = result + ")";
        console.log("        + " + result);
      });
    }

    async function test(terms, rates, testTerms, expectedRates, decimals) {
      const replacePoints = await simpleCurve.replacePoints(terms, rates);
      const receipt = await replacePoints.wait();
      console.log("        replacePoints(" + JSON.stringify(terms) + ", " + JSON.stringify(rates.map((x) => { return ethers.utils.formatUnits(x, decimals); })) + ") - gasUsed: " + receipt.gasUsed.toString());
      printEvents(simpleCurve, receipt);

      const pointsLength = await simpleCurve.pointsLength();
      console.log("        pointsLength: " + pointsLength);

      for (let i = 0; i < pointsLength; i++) {
        const point = await simpleCurve.points(i);
        console.log("        point(" + i + "): term: " + point.term + " => rate: " + ethers.utils.formatUnits(point.rate, decimals));
      }

      for (let i = 0; i < testTerms.length; i++) {
        const rate = await simpleCurve.getRate(testTerms[i]);
        console.log("        getRate(term: " + testTerms[i] + "): " + ethers.utils.formatUnits(rate, decimals) + ", expected: " + ethers.utils.formatUnits(expectedRates[i], decimals));
        expect(rate.toString()).to.equal(expectedRates[i].toString());
      }
    }

    async function expectException(message, searchString, promise) {
      try {
        await promise;
      } catch (e) {
        assert(e.toString().indexOf(searchString) >= 0, message + " - '" + searchString + "' not found in error message '" + e.toString() + "'");
        console.log("        " + message + " - Exception '" + searchString + "' thrown as expected");
        return;
      }
      assert.fail(message + " - Exception '" + searchString + "' was not thrown as expected");
    }

    SimpleCurve = await ethers.getContractFactory("SimpleCurve");
    const setup1a = [];
    setup1a.push(SimpleCurve.deploy([1, 2], [10, 20]));
    const [simpleCurve] = await Promise.all(setup1a);
    const deployTransactionReceipt = await simpleCurve.deployTransaction.wait();
    console.log("        simpleCurve deployment - gasUsed: " + deployTransactionReceipt.gasUsed.toString());
    printEvents(simpleCurve, deployTransactionReceipt);
    const owner = await simpleCurve.owner();
    console.log("        owner: " + owner);

    let deployerSigner;
    [deployerSigner] = await ethers.getSigners();
    const expectedOwner = await deployerSigner.getAddress();
    expect(owner).to.equal(expectedOwner);

    console.log("        --- Test 1 - Increasing rates ---");
    let terms1 = [2, 5, 10, 100];
    let rates1 = [20, 50, 100, 1000];
    let testTerms1 = [1, 2, 3, 5, 7, 10, 100, 101, 10000];
    let expectedRates1 = [20, 20, 30, 50, 70, 100, 1000, 1000, 1000];
    await test(terms1, rates1, testTerms1, expectedRates1, 0);

    console.log("        --- Test 2 - Decreasing rates ---");
    let terms2 = [2, 4, 6, 8, 10];
    let rates2 = [10, 8, 6, 4, 2];
    let testTerms2 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    let expectedRates2 = [10, 10, 9, 8, 7, 6, 5, 4, 3, 2, 2];
    await test(terms2, rates2, testTerms2, expectedRates2, 0);

    console.log("        --- Test 3a - Unixtime and BigNumber ---");
    let terms3 = [BigNumber.from("1604716674"), BigNumber.from("1604736674")];
    let rates3 = [BigNumber.from("1000000000000000000000000"), BigNumber.from("2000000000000000000000000")];
    let testTerms3 = [BigNumber.from("1604716674"), BigNumber.from("1604726674"), BigNumber.from("1604726675"), BigNumber.from("1604726684"), BigNumber.from("1604726774"), BigNumber.from("1604727674")];
    let expectedRates3 = [BigNumber.from("1000000000000000000000000"), BigNumber.from("1500000000000000000000000"), BigNumber.from("1500050000000000000000000"), BigNumber.from("1500500000000000000000000"), BigNumber.from("1505000000000000000000000"), BigNumber.from("1550000000000000000000000")];
    await test(terms3, rates3, testTerms3, expectedRates3, 18);

    console.log("        --- Test 3b - Replace point ---");
    let replaceTerm3 = 1604746674;
    let replaceRate3 = BigNumber.from("3000000000000000000000000");
    const replacePoint3 = await simpleCurve.replacePoint(1, replaceTerm3, replaceRate3);
    const receipt3 = await replacePoint3.wait();
    printEvents(simpleCurve, receipt3);
    const rate3 = await simpleCurve.getRate(1604746674);
    console.log("        Replaced rate3: " + ethers.utils.formatUnits(rate3, 18) + " vs expected " + ethers.utils.formatUnits(replaceRate3, 18) + " - gasUsed: " + receipt3.gasUsed.toString());
    expect(rate3.toString()).to.equal(replaceRate3.toString());

    console.log("        --- Test 4 - Linear from (0, 0) ---");
    let terms4 = [0, 365];
    let rates4 = [0, 36500];
    let testTerms4 = [0, 1, 10, 100, 1000];
    let expectedRates4 = [0, 100, 1000, 10000, 36500];
    await test(terms4, rates4, testTerms4, expectedRates4, 0);

    console.log("        --- Test 5 - Variable rates 1 ---");
    let terms5 = [2, 5, 10, 100];
    let rates5 = [20, 500, 100, 1000];
    let testTerms5 = [1, 2, 3, 5, 7, 10, 99, 100, 101, 10000];
    let expectedRates5 = [20, 20, 180, 500, 340, 100, 990, 1000, 1000, 1000];
    await test(terms5, rates5, testTerms5, expectedRates5, 0);

    console.log("        --- Test 6a - Variable rates 2 ---");
    let terms6 = [20, 50, 100, 1000];
    let rates6 = [20, 500, 100, 1000];
    let testTerms6 = [10, 20, 30, 50, 70, 100, 990, 999, 1000, 1010, 100000];
    let expectedRates6 = [20, 20, 180, 500, 340, 100, 990, 999, 1000, 1000, 1000];
    await test(terms6, rates6, testTerms6, expectedRates6, 0);

    console.log("        --- Test 6b - Replace point with errors ---");
    await expectException("Replace 1st point with term equal to 2nd point", "Invalid term", simpleCurve.replacePoint(0, 50, 20));
    await expectException("Replace 2nd point with term equal to 1st point", "Invalid term", simpleCurve.replacePoint(1, 20, 20));
    await expectException("Replace 2nd point with term greater than 3rd point", "Invalid term", simpleCurve.replacePoint(1, 101, 20));
    await expectException("Replace 3rd/last point with term equal to 2nd point", "Invalid term", simpleCurve.replacePoint(3, 100, 20));

    console.log("        --- Test 7 - Equal rates ---");
    let terms7 = [2, 5, 10, 100, 200];
    let rates7 = [100, 100, 200, 200, 100];
    let testTerms7 = [1, 2, 3, 5, 7, 10, 99, 100, 101, 10000];
    let expectedRates7 = [100, 100, 100, 100, 140, 200, 200, 200, 199, 100];
    await test(terms7, rates7, testTerms7, expectedRates7, 0);

    console.log("        --- Test Completed ---");
    console.log("");
  });
});
