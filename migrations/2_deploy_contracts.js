var LibCLLa = artifacts.require("./libs/LibCLLa.sol");
var LibCLLu = artifacts.require("./libs/LibCLLu.sol");
var SafeMath = artifacts.require("../libs/SafeMath.sol");
var BluePool = artifacts.require("./BluePool.sol");

    module.exports = function (deployer) {
        deployer.deploy(LibCLLa);
        deployer.deploy(LibCLLu);
        deployer.deploy(SafeMath);
        deployer.link(LibCLLa, BluePool);
        deployer.link(LibCLLu, BluePool);
        deployer.link(SafeMath,BluePool);
        deployer.deploy(BluePool);
 
};
