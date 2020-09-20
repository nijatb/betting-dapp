var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "burger ball wild target shiver hundred laundry donor smooth burden special pelican";

require('babel-register');
require('babel-polyfill');

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 9545,
      network_id: "*" // Match any network id
    },
    ropsten: {
      provider: function() { return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/D9vSUKqFOdFAu9YjiUzc")},
      network_id: 3,
      gas: 4612388
    },
    rinkeby:{
      provider: function() { return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/D9vSUKqFOdFAu9YjiUzc")},
      network_id: 4,
      gas: 4612388 
    }
  }
};
