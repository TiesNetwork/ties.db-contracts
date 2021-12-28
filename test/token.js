const TieToken = artifacts.require("./TieToken.sol");

const logger = require('./helpers/logger');

const testRpc = require('./helpers/testRpc');

const acc = require('./helpers/accounts');
const getAccounts = acc.getAccounts;

const tok = require('./helpers/tokens');
const asTokens = tok.asTokens;

function toWei(amount, unit) {
    return web3.utils.toWei(web3.utils.toBN(amount), unit);
}

contract('TieToken', async function (clientAccounts) {
    let tokenContract;
    let accounts;

    before(async function(){

        accounts = await getAccounts(clientAccounts[0], 4);

        tokenContract = await TieToken.new(accounts[0]);
        logger.debug("TieToken.address = " + tokenContract.address);
        await tokenContract.setMinter(accounts[2], {from: accounts[0]});
        logger.debug("TieToken.minter = " + accounts[2]);
    });

    it("should not mint by owner", async function () {
    	await testRpc.assertThrow('mint should have thrown', async function() {
            await tokenContract.mint(accounts[3], asTokens(100), {from: accounts[0]});
        });
    });

    it("should mint by minter", async function() {
        await tokenContract.mint(accounts[1], toWei(48000, 'ether'), {from: accounts[2]});
        let balance = await tokenContract.balanceOf(accounts[1]);
        let shouldbe = toWei(48000, 'ether');
        assert.equal(balance.toString(), shouldbe.toString(), "There should be 48000 tokens");
    });

    it("should not be able to transfer", async function() {
        await tokenContract.approve(accounts[3], asTokens(1000), {from: accounts[1]});

        await testRpc.assertThrow('token transfer should have thrown', async () => {
            await tokenContract.transfer(accounts[3], toWei(10, 'ether'));
        });

        await testRpc.assertThrow('token transferFrom should have thrown', async () => {
            await tokenContract.transferFrom(accounts[1], accounts[3], toWei(10, 'ether'), {from: accounts[3]});
        });
    });

    it("should transfer be enabled by owner", async function() {
        await tokenContract.enableTransfer(true, {from: accounts[0]});
        assert.ok(await tokenContract.transferEnabled(), 'Transfer should have been enabled');
    });

    it("should transfer succeed", async function() {
        let prevBalance = await tokenContract.balanceOf(accounts[3]);
        await tokenContract.transfer(accounts[3], toWei(10, 'ether'), {from: accounts[1]});
        let newBalance = await tokenContract.balanceOf(accounts[3]);

        assert.ok(prevBalance.add(toWei(10, 'ether')).toString(), newBalance.toString(), 'Tokens should have been transferred');

        await tokenContract.transferFrom(accounts[1], accounts[3], toWei(10, 'ether'), {from: accounts[3]});
        assert.ok(prevBalance.add(toWei(20, 'ether')).toString(), newBalance.toString(), 'Tokens should have been transferred from');
        
    });
});
