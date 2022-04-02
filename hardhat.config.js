require("@nomiclabs/hardhat-waffle");
// usePlugin("@nomiclabs/hardhat-waffle");

// This is a sample Buidler task. To learn how to create your own go to
// https://buidler.dev/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.getAddress());
  }
});

// You have to export an object to set up your config
// This object can have the following optional entries:
// defaultNetwork, networks, solc, and paths.
// Go to https://buidler.dev/config/ to learn more
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      accounts: [
        { privateKey: "0x56554ba7c55d35844ffe3b132ad064faa810780fe73b952f8c8593facfcb1eaa", balance: "10000000000000000000000", },
        { privateKey: "0x9f9752b9387aa98f6b6ef115a34be9941264876381692b24b85fdd015d660124", balance: "10000000000000000000000", },
        { privateKey: "0x3f4fb8f7153d89ff1e4f8fb3f99081cca78c8e2fb667bb77e9f752569ebea0dc", balance: "10000000000000000000000", },
        { privateKey: "0x4083f1f171d5a00096e5b82f16e4a36cd87d6ce6cd344cc470574c8173fcdf0f", balance: "10000000000000000000000", },
        { privateKey: "0xd4064564a145d1c22fc05dd9e760cdfe9d816cfb5e8515a69d2b3abc5f94ab60", balance: "10000000000000000000000", },
        { privateKey: "0xb259dc97d0a3217630778ba6374d51db929a46df05c6bd57b4b8defe7ac5c0ff", balance: "10000000000000000000000", },
        { privateKey: "0xadf9eb6891ca19c3b7b53816167703f71262e0349fa064007d2605f716ece1f3", balance: "10000000000000000000000", },
        { privateKey: "0xa43de2946daea8d9174000c7ddbb76c62c688be96744682217616282e6d1d91c", balance: "10000000000000000000000", },
        { privateKey: "0x088e00f9735d37699c6d3608fa82e595fefef47c74a752de451c58b56d203fc7", balance: "10000000000000000000000", },
        { privateKey: "0xad968434bf82b4cab68a26d098d2b86cf608a29b367fa974c6702f62abebd99d", balance: "10000000000000000000000", },
      ],
      gasPrice: 80000000000,
      allowUnlimitedContractSize: true, // TODO: Remove after debugging
    },
    // rinkeby: {
    //   url: "https://rinkeby.infura.io/v3/123abc123abc123abc123abc123abcde",
    //   accounts: [privateKey1, privateKey2, ...]
    // }
  },
  solidity: {
    "version": "0.8.0",
    // "version": "0.7.5",
    "settings": {
      "optimizer": {
        "enabled": true,
        "runs": 200
      }
    }
  },
};
