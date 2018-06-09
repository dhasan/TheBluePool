const BluePool = artifacts.require("BluePool");

contract('BluePool', async (accounts) => {

it("Create Token", async () => {
	let bluepool = await BluePool.deployed();
	await bluepool.createToken("VPT","VPT",38000,5);
    //await bluepool.send(1e+18, {from: accounts[1]});

     //let bal = await web3.eth.getBalance(bluepool.address);
     //assert.equal(bal, 2e+18);

  });

})


