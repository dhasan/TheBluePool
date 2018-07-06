var BluePool = artifacts.require("./BluePool.sol");
var BigNumber = require('bignumber.js');
//4189374bc6a7ef9db3

var pricebase = new BigNumber('100000000000000000000',16);

    module.exports = function (deployer, network, accounts) {
        var bluep;
        BluePool.deployed().then(function(instance) {
            bluep = instance;
            console.log(new BigNumber(0.001).times(pricebase).ceil().toString(16));
            return instance.createPair("BPSETH", 1, 0,new BigNumber(0.001).times(pricebase).ceil(), 20, {from: accounts[0]}); 

        }).then(function(result) {
                console.log("4 done");
            }).catch(function(e) {
                // There was an error! Handle it.
                console.log(e);
            });
    };

