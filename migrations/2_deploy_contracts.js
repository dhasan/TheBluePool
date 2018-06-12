var LibCLLa = artifacts.require("./libs/LibCLLa.sol");
var LibCLLu = artifacts.require("./libs/LibCLLu.sol");
var SafeMath = artifacts.require("../libs/SafeMath.sol");
var BluePool = artifacts.require("./BluePool.sol");

    module.exports = function (deployer, network, accounts) {
    	deployer.then(async () => {
        await deployer.deploy(LibCLLa, {from: accounts[0]});
        await deployer.deploy(LibCLLu, {from: accounts[0]});
        await deployer.deploy(SafeMath, {from: accounts[0]});
        await deployer.link(LibCLLa, BluePool);
        await deployer.link(LibCLLu, BluePool);
        await deployer.link(SafeMath,BluePool);
        await deployer.deploy(BluePool, 20,10,{from: accounts[0], gas:3000000});
    })
 
};
