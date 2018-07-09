var LibCLLa = artifacts.require("./libs/LibCLLa.sol");
var LibCLLu = artifacts.require("./libs/LibCLLu.sol");
var LibPair = artifacts.require("./libs/LibPair.sol");
var LibPairAsk = artifacts.require("./libs/LibPairAsk.sol");
var LibPairBid = artifacts.require("./libs/LibPairBid.sol");
var LibToken = artifacts.require("./libs/LibToken.sol");
var SafeMath = artifacts.require("../libs/SafeMath.sol");
var BluePool = artifacts.require("./BluePool.sol");
var ECRecovery = artifacts.require("./libs/ECRecovery.sol");

    module.exports = function (deployer, network, accounts) {

        deployer.deploy(LibCLLu, {from: accounts[0]}).then(function() {
            return deployer.deploy(SafeMath, {from: accounts[0]});

        }).then(function(result) {
            deployer.link(SafeMath, LibToken);
            return deployer.deploy(LibToken, {from: accounts[0]});
        }).then(function(result) {
            deployer.link(SafeMath, LibPairAsk);
            deployer.link(LibCLLu, LibPairAsk);
            deployer.link(LibToken, LibPairAsk);
            return deployer.deploy(LibPairAsk, {from: accounts[0]});
        }).then(function(result) {
            deployer.link(SafeMath, LibPairBid);
            deployer.link(LibCLLu, LibPairBid);
            deployer.link(LibToken, LibPairBid);
            return deployer.deploy(LibPairBid, {from: accounts[0]});
        }).then(function(result) {
            deployer.link(SafeMath, LibPair);
            deployer.link(LibCLLu, LibPair);
            deployer.link(LibToken, LibPair);
            deployer.link(LibPairAsk, LibPair);
            deployer.link(LibPairBid, LibPair);
            return deployer.deploy(LibPair, {from: accounts[0]});
        }).then(function(result){
            return deployer.deploy(ECRecovery, {from: accounts[0]});
        }).then(function(result){
            deployer.link(ECRecovery, BluePool);
            deployer.link(SafeMath, BluePool);
            deployer.link(LibCLLu, BluePool);
            deployer.link(LibToken, BluePool);
            deployer.link(LibPair, BluePool);
            return deployer.deploy(BluePool, {from: accounts[0]});
        }).then(function(result){
            return deployer.deploy(LibCLLa, {from: accounts[0]});
        }).then(function(result).{
             console.log("2 done");
        });
    /*   
    deployer.deploy(LibCLLu, {from: accounts[0]}).then(function() {
        return deployer.deploy(SafeMath, {from: accounts[0]}).then(function() {
            deployer.link(SafeMath, LibToken);
            return deployer.deploy(LibToken, {from: accounts[0]}).then(function() {
                deployer.link(SafeMath, LibPairAsk);
                deployer.link(LibCLLu, LibPairAsk);
                deployer.link(LibToken, LibPairAsk);
                return deployer.deploy(LibPairAsk, {from: accounts[0]}).then(function() {

                    deployer.link(SafeMath, LibPairBid);
                    deployer.link(LibCLLu, LibPairBid);
                    deployer.link(LibToken, LibPairBid);
                    return deployer.deploy(LibPairBid, {from: accounts[0]}).then(function() {

                        deployer.link(SafeMath, LibPair);
                        deployer.link(LibCLLu, LibPair);
                        deployer.link(LibToken, LibPair);
                        deployer.link(LibPairAsk, LibPair);
                        deployer.link(LibPairBid, LibPair);
                        return deployer.deploy(LibPair, {from: accounts[0]}).then(function() {
                            deployer.link(SafeMath, BluePool);
                            deployer.link(LibCLLu, BluePool);
                            deployer.link(LibToken, BluePool);
                            deployer.link(LibPair, BluePool);
                            return deployer.deploy(BluePool, {from: accounts[0]}).then(function() {
                                return deployer.deploy(LibCLLa, {from: accounts[0]}).then(function() {
                                    console.log("2 done");
                                });
                            });
                        });
                    });
                });

            });
        });
    });
*/

};


/*
LibCLLu - 106 692
SafeMath - 74 748
LibToken - 74 748
LibPairAsk - 106 884
LibPairBid - 106 884
LibPair    -  106 692

 */

        
 

//0x2ab06f20e2CEe5c20d84F37a27eBc77feA19003b
//0x0acfabd360b9b3e21450ef7e29ca2383ed090c7a

/*
get Accound address[0]
web3.eth.getAccounts((error, result) =>{console.log(result[0])})


get main accound balance
web3.eth.getAccounts((error, result) =>{web3.eth.getBalance(result[0], function (error, result2) {console.log(result2.toNumber())})})

*/


