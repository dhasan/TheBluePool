var LibCLLa = artifacts.require("./libs/LibCLLa.sol");
var LibCLLu = artifacts.require("./libs/LibCLLu.sol");
var SafeMath = artifacts.require("../libs/SafeMath.sol");
var BluePool = artifacts.require("./BluePool.sol");

    module.exports = function (deployer, network, accounts) {
        deployer.deploy(LibCLLa, {from: accounts[0]});
        deployer.deploy(LibCLLu, {from: accounts[0]});
        deployer.deploy(SafeMath, {from: accounts[0]});
        deployer.link(LibCLLa, BluePool);
        deployer.link(LibCLLu, BluePool);
        deployer.link(SafeMath,BluePool);
        deployer.deploy(BluePool, 20,10,{from: accounts[0], gas:3000000});
 
};
