const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const SECONDS_PER_DAY = 24 * 60 * 60;
const SECONDS_PER_YEAR = 365 * 24 * 60 * 60;
const ROLE = {SETPERMISSION: 0, SETCONFIG: 1, MINTTOKENS: 2, BURNTOKENS: 3, RECOVERTOKENS: 4};
const { BigNumber } = require("ethers");
const util = require('util');
const { expect, assert } = require("chai");

class Data {

  constructor() {
    this.accounts = [];
    this.accountNames = {};
    this.contractsByAddress = {};
    this.baseBlock = null;

    this.tokenContracts = [];
    this.symbols = [];
    this.decimals = [];

    // OptinoGov testing
    this.ogToken = null;
    this.ogdToken = null;
    this.ogRewardCurve = null;
    this.voteWeightCurve = null;
    this.optinoGov = null;
    this.fee0Token = null;
    this.fee1Token = null;
    this.fee2Token = null;
    this.stakingRewardCurve = null;
    this.stakingFactory = null;

    // this.ethUsd = BigNumber.from("385.67");
    this.ethUsd = ethers.utils.parseUnits("385.67", 18);
  }

  async init() {
    [this.deployerSigner, this.user1Signer, this.user2Signer, this.user3Signer, this.user4Signer] = await ethers.getSigners();
    [this.deployer, this.user1, this.user2, this.user3, this.user4] = await Promise.all([this.deployerSigner.getAddress(), this.user1Signer.getAddress(), this.user2Signer.getAddress(), this.user3Signer.getAddress(), this.user4Signer.getAddress()]);
    this.addAccount(this.deployer, "Deployer");
    this.addAccount(this.user1, "User1");
    this.addAccount(this.user2, "User2");
    this.addAccount(this.user3, "User3");
    this.addAccount(this.user4, "User4");
    this.baseBlock = await ethers.provider.getBlockNumber();
  }

  addAccount(account, accountName) {
    this.accounts.push(account);
    this.accountNames[account.toLowerCase()] = accountName;
    console.log("        Address " + account + " => " + this.getShortAccountName(account));
  }

  addContract(contract, contractName) {
    this.contractsByAddress[contract.address.toLowerCase()] = {
      address: contract.address,
      name: contractName,
      interface: contract.interface,
    };
  }

  getShortAccountName(address) {
    if (address == ZERO_ADDRESS) {
      return "ETH|null:" + ZERO_ADDRESS.substring(0, 6);
    }
    if (address != null) {
      var a = address.toLowerCase();
      var n = this.accountNames[a];
      if (n !== undefined) {
        return n + ":" + address.substring(0, 6);
      }
    }
    return address;
  }

  async setOptinoGovData(ogToken, ogdToken, ogRewardCurve, voteWeightCurve, optinoGov, fee0Token) {
    this.ogToken = ogToken;
    this.ogdToken = ogdToken;
    this.ogRewardCurve = ogRewardCurve;
    this.voteWeightCurve = voteWeightCurve;
    this.optinoGov = optinoGov;
    this.fee0Token = fee0Token;
    this.addAccount(this.ogToken.address, "OGToken");
    this.addAccount(this.ogdToken.address, "OGDToken");
    this.addAccount(this.ogRewardCurve.address, "OGRewardCurve");
    this.addAccount(this.voteWeightCurve.address, "VoteWeightCurve");
    this.addAccount(this.optinoGov.address, "OptinoGov");
    this.addAccount(this.fee0Token.address, "Fee0Token");

    this.addContract(this.ogToken, "OGToken");
    this.addContract(this.ogdToken, "OGDToken");
    this.addContract(this.ogRewardCurve, "OGRewardCurve");
    this.addContract(this.voteWeightCurve, "VoteWeightCurve");
    this.addContract(this.optinoGov, "OptinoGov");
    this.addContract(this.fee0Token, "Fee0Token");

    this.tokenContracts = [optinoGov, ogToken, ogdToken, fee0Token];
    for (let i = 0; i < this.tokenContracts.length; i++) {
      const tokenContract = this.tokenContracts[i];
      if (tokenContract != null) {
        const _symbol = tokenContract.symbol();
        const _decimals = tokenContract.decimals();
        const [symbol, decimals] = await Promise.all([_symbol, _decimals]);
        this.symbols.push(symbol);
        this.decimals.push(decimals);
      } else {
        this.symbols.push("???");
        this.decimals.push(18);
      }
    }
  }

  async setOGDTokenData(ogdToken, fee0Token, fee1Token, fee2Token) {
    this.ogdToken = ogdToken;
    this.fee0Token = fee0Token;
    this.fee1Token = fee1Token;
    this.fee2Token = fee2Token;
    this.addAccount(this.ogdToken.address, "OGDToken");
    this.addAccount(this.fee0Token.address, "Fee0Token");
    this.addAccount(this.fee1Token.address, "Fee1Token");
    this.addAccount(this.fee2Token.address, "Fee2Token");
    this.addContract(this.ogdToken, "OGDToken");
    this.addContract(this.fee0Token, "Fee0Token");
    this.addContract(this.fee1Token, "Fee1Token");
    this.addContract(this.fee2Token, "Fee2Token");
    this.tokenContracts = [ogdToken, fee0Token, fee1Token, fee2Token];
    for (let i = 0; i < this.tokenContracts.length; i++) {
      const tokenContract = this.tokenContracts[i];
      if (tokenContract != null) {
        const _symbol = tokenContract.symbol();
        const _decimals = tokenContract.decimals();
        const [symbol, decimals] = await Promise.all([_symbol, _decimals]);
        this.symbols.push(symbol);
        this.decimals.push(decimals);
      } else {
        this.symbols.push("???");
        this.decimals.push(18);
      }
    }
  }

  async setStakingFactoryData(ogToken, ogdToken, stakingRewardCurve, fee0Token, stakingFactory) {
    this.ogToken = ogToken;
    this.ogdToken = ogdToken;
    this.stakingRewardCurve = stakingRewardCurve;
    this.fee0Token = fee0Token;
    this.stakingFactory = stakingFactory;
    this.addAccount(this.ogToken.address, "OGToken");
    this.addAccount(this.ogdToken.address, "OGDToken");
    this.addAccount(this.fee0Token.address, "Fee0Token");
    this.addAccount(this.stakingRewardCurve.address, "StakingRewardCurve");
    this.addAccount(this.stakingFactory.address, "StakingFactory");
    this.addContract(this.ogToken, "OGToken");
    this.addContract(this.ogdToken, "OGDToken");
    this.addContract(this.fee0Token, "Fee0Token");
    this.addContract(this.stakingRewardCurve, "StakingRewardCurve");
    this.addContract(this.stakingFactory, "StakingFactory");
    this.tokenContracts = [ogToken, ogdToken, fee0Token];
    for (let i = 0; i < this.tokenContracts.length; i++) {
      const tokenContract = this.tokenContracts[i];
      if (tokenContract != null) {
        const _symbol = tokenContract.symbol();
        const _decimals = tokenContract.decimals();
        const [symbol, decimals] = await Promise.all([_symbol, _decimals]);
        this.symbols.push(symbol);
        this.decimals.push(decimals);
      } else {
        this.symbols.push("???");
        this.decimals.push(18);
      }
    }
  }

  async addStakingData(staking) {
    this.addAccount(staking.address, "Staking");
    this.addContract(staking, "Staking");
    const _symbol = staking.symbol();
    const _decimals = staking.decimals();
    const [symbol, decimals] = await Promise.all([_symbol, _decimals]);
    this.tokenContracts.push(staking);
    this.symbols.push(symbol);
    this.decimals.push(decimals);
  }

  padToken(s, decimals) {
    decimals = parseInt(decimals);
    var o = ethers.utils.formatUnits(s, decimals);
    while (o.length < 25) {
      o = " " + o;
    }
    return o;
  }

  padLeft(s, n) {
    var o = s.toString();
    while (o.length < n) {
      o = " " + o;
    }
    return o;
  }

  padLeft0(s, n) {
    var result = s.toString();
    while (result.length < n) {
      result = "0" + result;
    }
    return result;
  }

  padRight(s, n) {
    var o = s;
    while (o.length < n) {
      o = o + " ";
    }
    return o;
  }

  addressToHex64(address) {
    if (address.substring(0, 2) == "0x") {
      return this.padLeft0(address.substring(2, 42).toLowerCase(), 64);
    } else {
      return this.padLeft0(address.substring(0, 40).toLowerCase(), 64);
    }
  }

  uint256ToHex64(number) {
    var bigNumber = BigNumber.from(number).toHexString();
    if (bigNumber.substring(0, 2) == "0x") {
      return this.padLeft0(bigNumber.substring(2, 66).toLowerCase(), 64);
    } else {
      return this.padLeft0(bigNumber.substring(0, 64).toLowerCase(), 64);
    }
  }

  stringToHex(s) {
    return web3.toHex(s).substring(2);
  }

  termString(term) {
    var s = "";
    if (term < 0) {
      term = -term;
      s = "-";
    }
    if (term == 0) {
      s = "0s";
    } else {
      var secs = parseInt(term);
      var mins = parseInt(secs / 60);
      secs = secs % 60;
      var hours = parseInt(mins / 60);
      mins = mins % 60;
      var days = parseInt(hours / 24);
      hours = hours % 24;
      var years = parseInt(days / 365);
      days = days % 365;
      if (years > 0) {
        s += years + "y";
      }
      if (days > 0) {
        s += days + "d";
      }
      if (hours > 0) {
        s += hours + "h";
      }
      if (mins > 0) {
        s += mins + "m";
      }
      if (secs > 0) {
        s += secs + "s";
      }
    }
    return s;
  }

  printEvent(log) {
    var address = log.address;
    var _contract = this.contractsByAddress[address.toLowerCase()];
    if (_contract != null) {
      var data = _contract.interface.parseLog(log);
      var result = _contract.name + "." + data.name + "(";
      let separator = "";
      data.eventFragment.inputs.forEach((a) => {
        result = result + separator + a.name + ": ";
        if (a.type == 'address') {
          result = result + this.getShortAccountName(data.args[a.name].toString());
        } else if (a.type == 'uint256') {
          if (a.name == 'tokens' || a.name == 'amount' || a.name == 'balance' || a.name == 'votes' || a.name == 'reward' || a.name == 'totalVotes' || a.name == 'forVotes' || a.name == 'againstVotes' || a.name == 'tokensBurnt' || a.name == 'tokensWithSlashingFactor' || a.name == 'rewardWithSlashingFactor' || a.name == 'cap') {
            // TODO Get decimals from token contracts, and only convert for token contract values
            result = result + ethers.utils.formatUnits(data.args[a.name], 18);
          } else if (a.name == 'slashingFactor' || a.name == 'rate') {
            result = result + ethers.utils.formatUnits(data.args[a.name], 16) + "%";
          } else if (a.name == 'term') {
            result = result + this.termString(data.args[a.name].toString());
          } else {
            result = result + data.args[a.name].toString();
          }
        } else {
          result = result + data.args[a.name].toString();
        }
        separator = ", ";
      });
      result = result + ")";
      console.log("        + " + result);
    } else {
      console.log("        + " + JSON.stringify(log));
    }
  }

  //-----------------------------------------------------------------------------
  // Pause for {x} seconds
  //-----------------------------------------------------------------------------
  pause(message, addSeconds) {
    var time = new Date((parseInt(new Date().getTime()/1000) + addSeconds) * 1000);
    console.log("        Pausing '" + message + "' for " + addSeconds + "s=" + time + " now=" + new Date());
    while ((new Date()).getTime() <= time.getTime()) {
    }
    console.log("        Paused '" + message + "' for " + addSeconds + "s=" + time + " now=" + new Date());
    console.log("        ");
  }

  async expectException(message, searchString, promise) {
    try {
      await promise;
    } catch (e) {
      assert(e.toString().indexOf(searchString) >= 0, message + " - '" + searchString + "' not found in error message '" + e.toString() + "'");
      console.log("        " + message + " - Exception '" + searchString + "' thrown as expected");
      return;
    }
    assert.fail(message + " - Exception '" + searchString + "' was not thrown as expected");
  }

  async printTxData(message, tx) {
    const receipt = await tx.wait();
    var fee = receipt.gasUsed.mul(tx.gasPrice);
    var feeUsd = fee.mul(this.ethUsd).div(ethers.utils.parseUnits("1", 18));
    console.log("        " + message + " - gasUsed: " + receipt.gasUsed.toString() + ", fee: " + ethers.utils.formatUnits(fee, 18) + ", feeUsd: " + ethers.utils.formatUnits(feeUsd, 18) + ", @ " + ethers.utils.formatUnits(tx.gasPrice, 9) + " gwei & " + ethers.utils.formatUnits(this.ethUsd,18) + " ETH/USD, " + tx.hash);
    receipt.logs.forEach((log) => {
      this.printEvent(log);
    });
  }

  async printBalances() {
    console.log("        ");
    const blockNumber = await ethers.provider.getBlockNumber();
    const block = await ethers.provider.getBlock("latest");
    const now = block.timestamp;
    const totalTokenBalances = [];
    let line = "         # Account                                        ΔETH";
    let separator = "        -- --------------------------- -----------------------";
    for (let t = 0; t < this.tokenContracts.length; t++) {
      line = line + "         " + this.padLeft(this.symbols[t] || "???", 16);
      separator = separator + " ------------------------";
      totalTokenBalances.push(BigNumber.from(0));
    }
    console.log(line);
    console.log(separator);
    for (let i = 0; i < this.accounts.length; i++) {
      let account = this.accounts[i];
      let etherBalanceBaseBlock = (await ethers.provider.getBalance(account, this.baseBlock)).toString();
      let etherBalance = await ethers.provider.getBalance(account, blockNumber);
      let etherBalanceDiff = etherBalance.sub(etherBalanceBaseBlock);
      let tokenBalances = [BigNumber.from(0), BigNumber.from(0)];
      for (let j = 0; j < this.tokenContracts.length; j++) {
        tokenBalances[j] = await this.tokenContracts[j].balanceOf(account);
        totalTokenBalances[j] = totalTokenBalances[j].add(tokenBalances[j]);
      }
      line = "        " + this.padLeft(i, 2) + " " + this.padRight(this.getShortAccountName(account), 25) + " " + this.padToken(etherBalanceDiff, 18);
      for (let t = 0; t < this.tokenContracts.length; t++) {
        line = line + this.padToken(tokenBalances[t] || BigNumber.from(0), this.decimals[t] || 18);
      }
      console.log(line);
    }
    console.log(separator);
    line = "           Totals                                             ";
    for (let t = 0; t < this.tokenContracts.length; t++) {
      line = line + this.padToken(totalTokenBalances[t] || BigNumber.from(0), this.decimals[t] || 18);
    }
    console.log(line);
    console.log(separator);
    console.log("        ");

    for (let i = 0; i < this.tokenContracts.length; i++) {
      let tokenContract = this.tokenContracts[i];
      let [symbol, name, decimals, totalSupply] = await Promise.all([tokenContract.symbol(), tokenContract.name(), tokenContract.decimals(), tokenContract.totalSupply()]);
      let owner;
      try {
        owner = await tokenContract.owner();
      } catch (e) {
        owner = "n/a";
      }
      console.log("        Token " + i + " symbol: '" + symbol + "', name: '" + name + "', decimals: " + decimals + ", totalSupply: " + ethers.utils.formatUnits(totalSupply, decimals) + ", owner: " + this.getShortAccountName(owner) + ", address: " + this.getShortAccountName(tokenContract.address) + " @ " + tokenContract.address);
      function roleString(r) {
        if (r == 0) {
          return "Set Permission";
        } else if (r == 1) {
          return "Set Config";
        } else if (r == 2) {
          return "Mint Tokens";
        } else if (r == 3) {
          return "Burn Tokens";
        } else if (r == 4) {
          return "Recover Tokens";
        } else {
          return "" + r;
        }
      }
      try {
        const permissionsLength = await tokenContract.permissionsLength();
        console.log("          # Permissioned account     Role            Active                  Maximum                Processed");
        console.log("         -- ------------------------ --------------- ------ ------------------------ ------------------------");
        for (let j = 0; j < permissionsLength; j++) {
          const _p = await tokenContract.getPermissionByIndex(j);
          console.log("         " + this.padLeft(j, 2) + " " +
            this.padRight(this.getShortAccountName(_p.account), 24) + " " +
            this.padRight(roleString(_p.role.toString()), 15) + " " +
            this.padRight(_p.active.toString() == 1 ? "Yes" : "No", 6) + " " +
            this.padLeft(ethers.utils.formatUnits(_p.maximum, 18), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(_p.processed, 18), 24));
        }
        console.log("         -- ------------------------ --------------- ------ ------------------------ ------------------------");
      } catch (e) {
      }
      if (symbol == "OptinoGov" && this.optinoGov != null) {
        let [ogToken, ogdToken, ogRewardCurve, voteWeightCurve, accountsLength, maxDuration, collectRewardForFee, collectRewardForDelay, proposalCost, proposalThreshold] = await Promise.all([this.optinoGov.ogToken(), this.optinoGov.ogdToken(), this.optinoGov.ogRewardCurve(), this.optinoGov.voteWeightCurve(), this.optinoGov.accountsLength(), this.optinoGov.maxDuration(), this.optinoGov.collectRewardForFee(), this.optinoGov.collectRewardForDelay(), this.optinoGov.proposalCost(), this.optinoGov.proposalThreshold()]);
        let [quorum, quorumDecayPerSecond, votingDuration, executeDelay, totalVotes] = await Promise.all([this.optinoGov.quorum(), this.optinoGov.quorumDecayPerSecond(), this.optinoGov.votingDuration(), this.optinoGov.executeDelay(), this.optinoGov.totalVotes()]);
        let [proposalsLength /*, stakeInfoLength*/] = await Promise.all([this.optinoGov.proposalsLength()/*, this.optinoGov.stakeInfoLength()*/]);
        console.log("        - ogToken              : " + this.getShortAccountName(ogToken));
        console.log("        - ogdToken             : " + this.getShortAccountName(ogdToken));
        console.log("        - ogRewardCurve        : " + this.getShortAccountName(ogRewardCurve));
        console.log("        - voteWeightCurve      : " + this.getShortAccountName(voteWeightCurve));
        let decimals = 18;
        console.log("        - maxDuration          : " + maxDuration + " seconds = " + maxDuration.div(60 * 60 * 24) + " days");
        console.log("        - collectRewardForFee  : " + ethers.utils.formatUnits(collectRewardForFee, 16) + "%");
        console.log("        - collectRewardForDelay: " + collectRewardForDelay + " seconds = " + collectRewardForDelay.div(60 * 60 * 24) + " days");
        console.log("        - proposalCost         : " + ethers.utils.formatUnits(proposalCost, decimals));
        console.log("        - proposalThreshold    : " + ethers.utils.formatUnits(proposalThreshold, 16) + "%");
        console.log("        - quorum               : " + ethers.utils.formatUnits(quorum, 16) + "%");
        console.log("        - quorumDecayPerSecond : " + ethers.utils.formatUnits(quorumDecayPerSecond.mul(60 * 60 * 24 * 365), 16) + "% per year");
        console.log("        - votingDuration       : " + votingDuration + " seconds = " + votingDuration.div(60 * 60 * 24) + " days");
        console.log("        - executeDelay         : " + executeDelay + " seconds = " + executeDelay.div(60 * 60 * 24) + " days");
        console.log("        - totalVotes           : " + ethers.utils.formatUnits(totalVotes, decimals));
        // console.log("        - proposalsLength      : " + proposalsLength);
        // console.log("        - stakeInfoLength      : " + stakeInfoLength);
        console.log("          # Account                Duration              End                    Rate%                  Balance                    Votes Delegatee                     Delegated Votes                  Accrued Accrual Term");
        console.log("         -- -------------------- ---------- ---------------- ------------------------ ------------------------ ------------------------ -------------------- ------------------------ ------------------------ ------------");
        for (let j = 0; j < accountsLength; j++) {
          const _a = await this.optinoGov.getAccountByIndex(j);
          const accruedReward = await tokenContract.accruedReward(_a.tokenOwner);
          console.log("         " + this.padLeft(j, 2) + " " +
            this.padRight(this.getShortAccountName(_a.tokenOwner), 20) + " " +
            this.padLeft(this.termString(_a.account.duration.toString()), 10) + " " +
            this.padLeft(this.termString(parseInt(_a.account.end.toString())-now), 16) + " " +
            this.padLeft(ethers.utils.formatUnits(_a.account.rate, 16), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(_a.account.balance, 18), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(_a.account.votes, 18), 24) + " " +
            this.padRight(this.getShortAccountName(_a.account.delegatee), 20) + " " +
            this.padLeft(ethers.utils.formatUnits(_a.account.delegatedVotes, 18), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(accruedReward[0], 18), 24) + " " +
            this.padLeft(accruedReward[1].toString(), 12));
        }
        console.log("         -- -------------------- ---------- ---------------- ------------------------ ------------------------ ------------------------ -------------------- ------------------------ ------------------------ ------------");
        console.log("          #      Start Executed Proposer             Description                                                                 For Votes            Against Votes");
        console.log("         -- ---------- -------- -------------------- ------------------------------------------------------------ ------------------------ ------------------------");
        for (let j = 0; j < proposalsLength; j++) {
          const proposal = await this.optinoGov.getProposal(j);
          // console.log("         " + this.padLeft(j, 2) + " " + JSON.stringify(proposal));
          console.log("         " + this.padLeft(j, 2) + " " +
            this.padLeft(this.termString(parseInt(proposal.start.toString())-now), 10) + " " +
            this.padLeft(proposal.executed.toString() == 0 ? "no": "yes", 8) + " " +
            this.padRight(this.getShortAccountName(proposal.proposer), 20) + " " +
            this.padRight(proposal.description, 60) + " " +
            this.padLeft(ethers.utils.formatUnits(proposal.forVotes, 18), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(proposal.againstVotes, 18), 24));
          for (let k = 0; k < proposal.targets.length; k++) {
              console.log("           + exec " + k + ". target: " + this.getShortAccountName(proposal.targets[k]) +
                ", value: " + ethers.utils.formatUnits(proposal._values[k], 18) +
                ", data: " + proposal.data[k]);
          }
          let separator = "";
          let votes = "";
          for (let k = 1; k < 5; k++) {
            const voted = await this.optinoGov.voted(j, this.accounts[k]);
            votes = votes + separator + this.getShortAccountName(this.accounts[k]) + ": " + voted;
            separator = ", ";
          }
          console.log("           + votes: " + votes);
        }
        console.log("         -- ---------- -------- -------------------- ------------------------------------------------------------ ------------------------ ------------------------");
      } else if (symbol == "OG") {
        const [cap, freezeCap] = await Promise.all([tokenContract.cap(), tokenContract.freezeCap()]);
        console.log("        - cap      : " + ethers.utils.formatUnits(cap, 18));
        console.log("        - freezeCap: " + freezeCap);
      } else if (symbol == "OGD") {
        const dividendTokensLength = parseInt(await tokenContract.dividendTokensLength());
        console.log("          # Dividend         Enabled                  Unclaimed");
        console.log("         -- ---------------- ------- --------------------------");
        let dividendHeader = "";
        let dividendSeparator = "         -- ------------------";
        for (let j = 0; j < dividendTokensLength; j++) {
          const dividendToken = await tokenContract.getDividendTokenByIndex(j);
          const unclaimedDividends = await tokenContract.unclaimedDividends(dividendToken[0]);
          dividendHeader = dividendHeader + this.padLeft("Owing " + this.getShortAccountName(dividendToken[0]), 24) + " " + this.padLeft("New " + this.getShortAccountName(dividendToken[0]), 24) + " ";
          dividendSeparator = dividendSeparator + " ------------------------ ------------------------";
          console.log("         " + this.padLeft(j, 2) + " " + this.padRight(this.getShortAccountName(dividendToken[0]), 18) + "  " + this.padRight(dividendToken[1].toString(), 6) + " " + this.padLeft(ethers.utils.formatUnits(unclaimedDividends, 18), 24));
        }
        console.log("         -- ---------------- ------- --------------------------");
        if (dividendTokensLength > 0) {
          console.log("          # Account            " + dividendHeader);
          console.log(dividendSeparator);
          for (let j = 1; j < this.accounts.length; j++) {
            let account = this.accounts[j];
            let accountName = this.getShortAccountName(account);
            if (!accountName.startsWith("Fee") && !accountName.startsWith("OG") && !accountName.startsWith("Vote")) {
              const dividendsOwing = await tokenContract.dividendsOwing(account);
              let result = "";
              let tokenList = dividendsOwing[0];
              let owingList = dividendsOwing[1];
              let newOwingList = dividendsOwing[2];
              for (let k = 0; k < dividendTokensLength; k++) {
                result = result + this.padLeft(ethers.utils.formatUnits(owingList[k], 18), 24) + " " + this.padLeft(ethers.utils.formatUnits(newOwingList[k], 18), 24) + " ";
              }
              console.log("         " + this.padLeft(j, 2) + " " + this.padRight(this.getShortAccountName(account), 18) + " " + result);
            }
          }
          console.log(dividendSeparator);
        }
      } else if (symbol.startsWith("OGS")) {
        const [stakingInfo, owner, accountsLength, weightedEnd, weightedEndNumerator, /*weightedDurationDenominator,*/ slashingFactor] = await Promise.all([tokenContract.getStakingInfo(), tokenContract.owner(), tokenContract.accountsLength(), tokenContract.weightedEnd(), tokenContract.weightedEndNumerator(), /*tokenContract.weightedDurationDenominator(),*/ tokenContract.slashingFactor()]);
        console.log("        - staking @ " + this.getShortAccountName(tokenContract.address) + ", owner: " + this.getShortAccountName(owner));
        console.log("          - dataType                   : " + stakingInfo.dataType  .toString());
        console.log("          - addresses                  : " + JSON.stringify(stakingInfo.addresses.map((x) => { return this.getShortAccountName(x); })));
        console.log("          - uints                      : " + JSON.stringify(stakingInfo.uints.map((x) => { return x.toString(); })));
        console.log("          - strings                    : " + JSON.stringify([stakingInfo.string0, stakingInfo.string1, stakingInfo.string2, stakingInfo.string3]));
        // console.log("          - weightedDurationDenominator: " + new BigNumber(weightedDurationDenominator.toString()).shiftedBy(-18));
        console.log("          - weightedEnd                : " + this.termString(parseInt(weightedEnd.toString())-now) + " " + weightedEnd + " = " + ethers.utils.formatUnits(weightedEndNumerator, decimals) + "/" + ethers.utils.formatUnits(totalSupply, decimals));
        console.log("          - slashingFactor             : " + ethers.utils.formatUnits(slashingFactor, 16) + "%");
        console.log("          # Account                    Duration              End      Index                    Rate%                  Balance           Accrued Reward Accrual Term");
        console.log("         -- -------------------- -------------- ---------------- ---------- ------------------------ ------------------------ ------------------------ ------------");
        for (let k = 0; k < accountsLength; k++) {
          const account = await tokenContract.getAccountByIndex(k);
          const accruedReward = await tokenContract.accruedReward(account.tokenOwner);
          console.log("         " + this.padLeft(k, 2) + " " +
            this.padRight(this.getShortAccountName(account.tokenOwner), 20) + " " +
            this.padLeft(this.termString(account.account.duration.toString()), 14) + " " +
            this.padLeft(this.termString(parseInt(account.account.end.toString())-now), 16) + " " +
            this.padLeft(account.account.index.toString(), 10) + " " +
            this.padLeft(ethers.utils.formatUnits(account.account.rate, 16), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(account.account.balance, 18), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(accruedReward[0], 18), 24) + " " +
            this.padLeft(accruedReward[1].toString(), 12));
        }
        console.log("         -- -------------------- -------------- ---------------- ---------- ------------------------ ------------------------ ------------------------ ------------");
      }
    }

    if (this.ogRewardCurve != null) {
      const [owner, pointsLength] = await Promise.all([this.ogRewardCurve.owner(), this.ogRewardCurve.pointsLength()]);
      console.log("        SimpleCurve " + this.getShortAccountName(this.ogRewardCurve.address) + " @ " + this.ogRewardCurve.address + ", owner: " + this.getShortAccountName(owner) + ", pointsLength: " + pointsLength);
        console.log("          #       Term                Rate APY%                  Rate/s%");
        console.log("         -- ---------- ------------------------ ------------------------");
        for (let j = 0; j < pointsLength; j++) {
          const point = await this.ogRewardCurve.points(j);
          console.log("         " + this.padLeft(j, 2) + " " +
            this.padLeft(this.termString(point.term.toString()), 10) + " " +
            this.padLeft(ethers.utils.formatUnits(point.rate, 16), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(point.rate.div(365 * 24 * 60 * 60), 16), 24));
        }
        console.log("         -- ---------- ------------------------ ------------------------");
    }
    if (this.voteWeightCurve != null) {
      const [owner, pointsLength] = await Promise.all([this.voteWeightCurve.owner(), this.voteWeightCurve.pointsLength()]);
      console.log("        SimpleCurve " + this.getShortAccountName(this.voteWeightCurve.address) + " @ " + this.voteWeightCurve.address + ", owner: " + this.getShortAccountName(owner) + ", pointsLength: " + pointsLength);
        console.log("          #       Term             Vote Weight%");
        console.log("         -- ---------- ------------------------");
        for (let j = 0; j < pointsLength; j++) {
          const point = await this.voteWeightCurve.points(j);
          console.log("         " + this.padLeft(j, 2) + " " +
            this.padLeft(this.termString(point.term.toString()), 10) + " " +
            this.padLeft(ethers.utils.formatUnits(point.rate, 16), 24));
        }
        console.log("         -- ---------- ------------------------");
    }
    if (this.stakingRewardCurve != null) {
      const [owner, pointsLength] = await Promise.all([this.stakingRewardCurve.owner(), this.stakingRewardCurve.pointsLength()]);
      console.log("        SimpleCurve " + this.getShortAccountName(this.stakingRewardCurve.address) + " @ " + this.stakingRewardCurve.address + ", owner: " + this.getShortAccountName(owner) + ", pointsLength: " + pointsLength);
        console.log("          #       Term                Rate APY%                  Rate/s%");
        console.log("         -- ---------- ------------------------ ------------------------");
        for (let j = 0; j < pointsLength; j++) {
          const point = await this.stakingRewardCurve.points(j);
          console.log("         " + this.padLeft(j, 2) + " " +
            this.padLeft(this.termString(point.term.toString()), 10) + " " +
            this.padLeft(ethers.utils.formatUnits(point.rate, 16), 24) + " " +
            this.padLeft(ethers.utils.formatUnits(point.rate.div(365 * 24 * 60 * 60), 16), 24));
        }
        console.log("         -- ---------- ------------------------ ------------------------");
    }

    if (this.stakingFactory != null) {
      console.log("        StakingFactory " + this.getShortAccountName(this.stakingFactory.address) + " @ " + this.stakingFactory.address);
      const [stakingTemplate, ogToken, ogdToken, stakingRewardCurve, stakingsLength] = await Promise.all([this.stakingFactory.stakingTemplate(), this.stakingFactory.ogToken(), this.stakingFactory.ogdToken(), this.stakingFactory.stakingRewardCurve(), this.stakingFactory.stakingsLength()]);
      console.log("        - stakingTemplate        : " + this.getShortAccountName(stakingTemplate));
      console.log("        - ogToken                : " + this.getShortAccountName(ogToken));
      console.log("        - ogdToken               : " + this.getShortAccountName(ogdToken));
      console.log("        - stakingRewardCurve     : " + this.getShortAccountName(stakingRewardCurve));
      console.log("        - stakingsLength         : " + stakingsLength);
      const Staking = await ethers.getContractFactory("Staking");
      for (let j = 0; j < stakingsLength; j++) {
        const stakingAddress = await this.stakingFactory.getStakingByIndex(j);
        const staking = Staking.attach(stakingAddress[1]);
        const [stakingInfo, owner, accountsLength, totalSupply, weightedEnd, slashingFactor] = await Promise.all([staking.getStakingInfo(), staking.owner(), staking.accountsLength(), staking.totalSupply(), staking.weightedEnd(), staking.slashingFactor()]);
        console.log("          - staking " + j + " @ " + this.getShortAccountName(stakingAddress[1]) + ", owner: " + this.getShortAccountName(owner));
      }
    }
    console.log("        ");
  }
}

/* Exporting the module */
module.exports = {
    ZERO_ADDRESS,
    SECONDS_PER_DAY,
    SECONDS_PER_YEAR,
    ROLE,
    Data
}

/*
// await ethers.provider.getBlockNumber().then((blockNumber) => {
//   console.log("Current block number: " + blockNumber);
// });

// await tokenContract.filters.Transfer(ZERO_ADDRESS, (data) => {
//   console.log("Transfer: " + util.inspect(data));
// });
// const iface = new ethers.utils.Interface(tokenContract.interface.abi);
// console.log("tokenContract.interface: " + util.inspect(tokenContract.interface));

// let x = tokenContract.filters.Transfer(ZERO_ADDRESS);
// console.log("        * Transfer: " + JSON.stringify(x));

// tokenContract.filters.forEach((x) => {
//   console.log("x: " + x);
// });


// provider.getTransactionReceipt(transactionHash).then(receipt => {
//   const logs = receipt.logs.filter(log => topics.some(t => t === log.topics[0]));
//   console.log('Printing array of events:');
//   const events = logs.map((log) => {
//     return iface.parseLog(log);
//   });
//   console.log(events);
// });
*/
