var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = "opinion destroy betray love turkey remote mother bike air tea floor computer";

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*"//1527617042614 // Match any network id
    },
    ropsten: {
      provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io/aLjkBlysDHdMmhTiiyXW"),
      network_id: 3
    }
  }
};
