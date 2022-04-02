const { expect, assert } = require("chai");
const { BigNumber } = require("ethers");
const util = require('util');
const { Decimal } = require("decimal.js");

let InterestUtils;

describe("TestInterestUtils", function() {
  it("TestInterestUtils - #0", async function() {
    Decimal.set({ precision: 30 });
    const SECONDS_PER_DAY = 60 * 60 * 24;
    const SECONDS_PER_YEAR = 365 * SECONDS_PER_DAY;

    TestInterestUtils = await ethers.getContractFactory("TestInterestUtils");

    console.log("        --- Test 1 - Deploy TestInterestUtils ---");
    const setup1a = [];
    setup1a.push(TestInterestUtils.deploy());
    const [testInterestUtils] = await Promise.all(setup1a);

    const _from = parseInt(new Date().getTime()/1000);
    const _to = parseInt(_from) + SECONDS_PER_YEAR * 2;
    const amount = 1000000;
    const _amount = ethers.utils.parseUnits(amount.toString(), 18);

    for (let date = _from; date < _to; date += (SECONDS_PER_DAY * 23.13)) {
      console.log("        date: " + new Date(date * 1000).toUTCString());
      const term = date - _from;
      for (let rate = 0; rate < 3; rate = parseFloat(rate) + 0.231345) {
        const exp = Decimal.exp(new Decimal(rate).mul(term).div(SECONDS_PER_YEAR).div(100));
        // console.log("      > exp: " + exp.toPrecision(30));
        const expectedFV = exp.mul(_amount.toString());
        const _rate = ethers.utils.parseUnits(rate.toString(), 16);
        const [fv, gasUsed] = await testInterestUtils.futureValue_(_amount, BigNumber.from(_from), BigNumber.from(date), _rate);
        const _diff = fv.sub(expectedFV.toFixed(0));
        const diff = ethers.utils.formatUnits(_diff, 18);
        console.log("          rate: " + rate + " => fv: " + ethers.utils.formatUnits(fv, 18) + " vs expectedFV: " + ethers.utils.formatUnits(expectedFV.toFixed(0), 18) + ", diff: " + ethers.utils.formatUnits(_diff.toString(), 18) + ", gasUsed: " + gasUsed);
        expect(parseFloat(diff.toString())).to.be.closeTo(0, 0.000000001, "Diff too large");
      }
    }

    console.log("        --- Test Completed ---");
    console.log("");
  });
});
