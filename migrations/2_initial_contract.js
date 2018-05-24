var LibCLLa = artifacts.require("./libs/LibCLLa.sol");
var SafeMath = artifacts.require("../libs/SafeMath.sol");
var TheBlueToken = artifacts.require("./TheBlueToken.sol");

    module.exports = function (deployer) {
    deployer.deploy(LibCLLa).then(() => {
        deployer.deploy(SafeMath).then(() => {
            deployer.link(LibCLLa, TheBlueToken);
            deployer.link(SafeMath,TheBlueToken);
            return deployer.deploy(TheBlueToken,"BPS", "Blue Pool Shares");
        });
    });
};
