var BluePool = artifacts.require("./BluePool.sol");

    module.exports = function (deployer, network, accounts) {
        var bluep;
        BluePool.deployed().then(function(instance) {
            bluep = instance;
            return instance.createPair("BPSETH", 1, 0, 10, 20, {from: accounts[0]}).then(function(result) {
                console.log("4 done");
            }).catch(function(e) {
                // There was an error! Handle it.
                console.log(e);
            }); 

        });
    };


/*
get Accound address[0]
web3.eth.getAccounts((error, result) =>{console.log(result[0])})


get main accound balance
web3.eth.getAccounts((error, result) =>{web3.eth.getBalance(result[0], function (error, result2) {console.log(result2.toNumber())})})

*/


