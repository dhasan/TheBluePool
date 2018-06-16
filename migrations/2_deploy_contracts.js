var LibCLLa = artifacts.require("./libs/LibCLLa.sol");
var LibCLLu = artifacts.require("./libs/LibCLLu.sol");
var LibPair = artifacts.require("./libs/LibPair.sol");
var LibToken = artifacts.require("./libs/LibToken.sol");
var SafeMath = artifacts.require("../libs/SafeMath.sol");
var BluePool = artifacts.require("./BluePool.sol");

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

        await deployer.deploy(BluePool, {from: accounts[0], gas:3000000});
    })
 
};
