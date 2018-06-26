var LibCLLa = artifacts.require("./libs/LibCLLa.sol");
var SafeMath = artifacts.require("../libs/SafeMath.sol");
var BluePool = artifacts.require("./BluePool.sol");
var BlueToken = artifacts.require("./BlueToken.sol");

    module.exports = function (deployer, network, accounts) {
        var bluep;
        BluePool.deployed().then(function(instance) {
            bluep = instance;
            return bluep.getTokensCount.call({from: accounts[0]});
        }).then(function(tokenscnt) {
            SafeMath.deployed().then(function(sminst) {
                deployer.link(SafeMath, BlueToken);
                LibCLLa.deployed().then(function(clainst) {
                    deployer.link(LibCLLa, BlueToken);
                    return deployer.deploy(BlueToken, tokenscnt, 38000, "BPS", "BluePoolShares", 5, {from: accounts[0]}).then(function(instance) {
                        return bluep.createToken(instance.address);
                    });  
                });
            });

        }).catch(function(e) {
            // There was an error! Handle it.
            console.log(e);
        });
    };


/*
get Accound address[0]
web3.eth.getAccounts((error, result) =>{console.log(result[0])})


get main accound balance
web3.eth.getAccounts((error, result) =>{web3.eth.getBalance(result[0], function (error, result2) {console.log(result2.toNumber())})})

*/


