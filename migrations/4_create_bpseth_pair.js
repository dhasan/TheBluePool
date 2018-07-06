var BluePool = artifacts.require("./BluePool.sol");
var BigNumber = require('bignumber.js');

var pricebase = new BigNumber('100000000000000000000',16);

    module.exports = function (deployer, network, accounts) {
        var bluep;
        BluePool.deployed().then(function(instance) {
            bluep = instance;
            return instance.createPair("BPSETH", 1, 0, new BigNumber(0.001).times(pricebase).ceil(), new BigNumber(0.002).times(pricebase).ceil(), {from: accounts[0]}); 

        }).then(function(result) {
                console.log("4 done");
            }).catch(function(e) {
                // There was an error! Handle it.
                console.log(e);
            });
    };

