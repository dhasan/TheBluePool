var LibCLLa = artifacts.require("./libs/LibCLLa.sol");
var LibCLLu = artifacts.require("./libs/LibCLLu.sol");
var LibPair = artifacts.require("./libs/LibPair.sol");
var LibToken = artifacts.require("./libs/LibToken.sol");
var SafeMath = artifacts.require("../libs/SafeMath.sol");
var BluePool = artifacts.require("./BluePool.sol");
var BlueToken = artifacts.require("./BlueToken.sol");

    module.exports = function (deployer, network, accounts) {
    	deployer.then(async () => {
        await deployer.deploy(LibCLLa, {from: accounts[0]});
        await deployer.deploy(LibCLLu, {from: accounts[0]});
        await deployer.deploy(SafeMath, {from: accounts[0]});

        await deployer.link(SafeMath, LibToken);
        await deployer.deploy(LibToken, {from: accounts[0]});
        await deployer.link(SafeMath, LibPair);
        await deployer.link(LibCLLu, LibPair);
        await deployer.link(LibToken, LibPair);
        await deployer.deploy(LibPair, {from: accounts[0]});

        await deployer.link(SafeMath, BluePool);
        await deployer.link(LibToken, BluePool);
        await deployer.link(LibPair, BluePool);

        await deployer.link(SafeMath, BlueToken);
        await deployer.link(LibCLLa, BlueToken);



        await deployer.deploy(BluePool, {from: accounts[0]});
    })
 
};


/*
get Accound address[0]
web3.eth.getAccounts((error, result) =>{console.log(result[0])})


get main accound balance
web3.eth.getAccounts((error, result) =>{web3.eth.getBalance(result[0], function (error, result2) {console.log(result2.toNumber())})})

*/


