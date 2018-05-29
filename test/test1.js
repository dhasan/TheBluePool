const BluePool = artifacts.require("BluePool");

contract('BluePool', async (accounts) => {

  it("Can deposit ETH", async () => {
     let contract = await BluePool.deployed();
     await contract.send(1e+18, {from: accounts[1]});
     await contract.send(1e+18, {from: accounts[1]});
     let bal = await web3.eth.getBalance(contract.address);
     assert.equal(bal, 2e+18);
  });

})


