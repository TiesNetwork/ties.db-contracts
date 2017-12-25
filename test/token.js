const testRpc = require('./helpers/testRpc');

let TieToken = artifacts.require("./TieToken.sol");

const decimals = 18;
const zeroes = Math.pow(10, decimals);
const zeroesBN = (web3.toBigNumber(10)).pow(web3.toBigNumber(decimals));

let secrets = [
    "0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3", //accounts[0]
    "0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f", //accounts[1]
    "0x0dbbe8e4ae425a6d2687f1a7e3ba17bc98c673636790f1b8ad91193c05875ef1", //accounts[2]
    "0xc88b703fb08cbea894b6aeff5a544fb92e78a18e19814cd85da83b71f772aa6c", //accounts[3]
];

contract('TieToken', async function (accounts) {
    let tokenContract;

    before(async function(){
        tokenContract = await TieToken.new(accounts[0]);
        await tokenContract.setMinter(accounts[2], {from: accounts[0]});
    });

    it("should not mint by owner", async function () {
    	await testRpc.assertThrow('mint should have thrown', async () => {
            await tokenContract.mint(accounts[3], 100*zeroes);
        });
    });

    it("should mint by minter", async function() {
        await tokenContract.mint(accounts[1], web3.toWei(48000, 'ether'), {from: accounts[2]});
        let balance = await tokenContract.balanceOf(accounts[1]);
        let shouldbe = web3.toWei(48000, 'ether');
        assert.equal(balance.toNumber(), shouldbe, "There should be 48000 tokens");
    });

    it("should not be able to transfer", async function() {
        await tokenContract.approve(accounts[3], 1000*zeroes, {from: accounts[1]});

        await testRpc.assertThrow('token transfer should have thrown', async () => {
            await tokenContract.transfer(accounts[3], web3.toWei(10, 'ether'));
        });

        await testRpc.assertThrow('token transferFrom should have thrown', async () => {
            await tokenContract.transferFrom(accounts[1], accounts[3], web3.toWei(10, 'ether'), {from: accounts[3]});
        });
    });

    it("should transfer be enabled by owner", async function() {
        await tokenContract.enableTransfer(true, {from: accounts[0]});
        assert.ok(await tokenContract.transferEnabled(), 'Transfer should have been enabled');
    });

    it("should transfer succeed", async function() {
        let prevBalance = await tokenContract.balanceOf(accounts[3]);
        await tokenContract.transfer(accounts[3], web3.toWei(10, 'ether'), {from: accounts[1]});
        let newBalance = await tokenContract.balanceOf(accounts[3]);

        assert.ok(prevBalance.add(web3.toWei(10, 'ether')).toNumber(), newBalance.toNumber(), 'Tokens should have been transferred');

        await tokenContract.transferFrom(accounts[1], accounts[3], web3.toWei(10, 'ether'), {from: accounts[3]});
        assert.ok(prevBalance.add(web3.toWei(20, 'ether')).toNumber(), newBalance.toNumber(), 'Tokens should have been transferred from');
        
    });
});
