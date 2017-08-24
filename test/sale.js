const testRpc = require('./helpers/testRpc');

let TieToken = artifacts.require("./TieToken.sol");
let Ico = artifacts.require("./TokenSale.sol");

const decimals = 18;
const zeroes = Math.pow(10, decimals);
const zeroesBN = (web3.toBigNumber(10)).pow(web3.toBigNumber(decimals));

let secrets = [
    "0x83c14ddb845e629975e138a5c28ad5a72a49252ea65b3d3ec99810c82751cc3a", //accounts[0]
    "0x52f3a1fa15405e1d5a68d7774ca45c7a3c7373a66c3c44db94a7f99a22c14d28", //accounts[1]
    "0xdc6a7f0cd30f86da5e55ca7b62ac1a86f5d8b76a796176152803e0fcbc253900", //accounts[2]
    "0xd3b6b98613ce7bd4636c5c98cc17afb0403d690f9c2b646726e08334583de101", //accounts[3]
];

contract('TokenSale', async function (accounts) {
    let tokenContract;
    let saleContract;
    let initialMultisigBalance;

    before(async function(){
        tokenContract = await TieToken.new(accounts[2]);
        saleContract = await Ico.new(tokenContract.address, accounts[2], accounts[3], accounts[3]);
        await tokenContract.setMinter(saleContract.address, {from: accounts[2]});
    });

    it("should not mint by owner", async function () {
    	await testRpc.assertThrow('mint should have thrown', async () => {
            await tokenContract.mint(accounts[3], 100*zeroes);
        });
    });

    it("should be valid bonuses", async function() {
    	assert.equal(20, (await saleContract.getBonus(web3.toWei(             0, 'ether'))).toNumber(), "1st bonus should be valid");
    	assert.equal(17, (await saleContract.getBonus(web3.toWei(  14*1000*1000, 'ether'))).toNumber(), "1st bonus should be valid");
    	assert.equal(15, (await saleContract.getBonus(web3.toWei(2*14*1000*1000, 'ether'))).toNumber(), "1st bonus should be valid");
    	assert.equal(12, (await saleContract.getBonus(web3.toWei(3*14*1000*1000, 'ether'))).toNumber(), "1st bonus should be valid");
    	assert.equal(10, (await saleContract.getBonus(web3.toWei(4*14*1000*1000, 'ether'))).toNumber(), "1st bonus should be valid");
    	assert.equal( 8, (await saleContract.getBonus(web3.toWei(5*14*1000*1000, 'ether'))).toNumber(), "1st bonus should be valid");
    	assert.equal( 6, (await saleContract.getBonus(web3.toWei(6*14*1000*1000, 'ether'))).toNumber(), "1st bonus should be valid");
    	assert.equal( 4, (await saleContract.getBonus(web3.toWei(7*14*1000*1000, 'ether'))).toNumber(), "1st bonus should be valid");
    	assert.equal( 2, (await saleContract.getBonus(web3.toWei(8*14*1000*1000, 'ether'))).toNumber(), "1st bonus should be valid");
    	assert.equal( 0, (await saleContract.getBonus(web3.toWei(9*14*1000*1000, 'ether'))).toNumber(), "1st bonus should be valid");
    });

    it("should not mint by ico before opening", async function() {
        await testRpc.assertThrow('ico buy should have thrown', async () => {
            await saleContract.buy(accounts[1], {value: web3.toWei(100, 'ether')});
        });
    });

    it("should not open by not an owner", async function() {
        await testRpc.assertThrow('ico buy should have thrown', async () => {
            await saleContract.open(true);
        });
    });

    it("should open successfully by owner", async function() {
        await saleContract.open(true, {from: accounts[2]});
        assert.ok(await saleContract.isOpen(), 'ICO should have been opened');
        initialMultisigBalance = await web3.eth.getBalance(accounts[2]);
    });

    it("should mint by ico", async function() {
        await saleContract.buy(accounts[1], {value: web3.toWei(100, 'ether')});
        let balance = await tokenContract.balanceOf(accounts[1]);
        let shouldbe = web3.toWei(48000, 'ether');
        assert.equal(balance.toNumber(), shouldbe, "There should be 48000 tokens");
    });

    it("should buy with fallback", async function() {
        await web3.eth.sendTransaction({from: accounts[0], to: saleContract.address, value: web3.toWei(29000, 'ether')});
        let balance = await tokenContract.balanceOf(accounts[0]);
        let shouldbe = web3.toWei(13920000, 'ether');
        assert.equal(balance.toNumber(), shouldbe, "There should be 13,920,000 tokens");
    });

    it("should not be able to buyAlt if non-authority", async function() {
        await testRpc.assertThrow('token transfer should have thrown', async () => {
            await saleContract.buyAlt(accounts[3], web3.toWei(100, 'ether'), "txHash", {from: accounts[1]});
        });
    });

    it("should buy with border crossing with buyAlt", async function() {
        await saleContract.buyAlt(accounts[3], web3.toWei(100, 'ether'), "txHash", {from: accounts[3]});
        //There were 32000 tokens left in 20% interval. We sell them for 66.(6) ether
        //and 33.(3) we spend on the next 17% interval
        let balance = await tokenContract.balanceOf(accounts[3]);
        let shouldbe = web3.toBigNumber(web3.toWei(32000, 'ether')).add(web3.toBigNumber("15600000000000000000312"));
        assert.equal(balance.toString(), shouldbe.toString(), "There should be tokens with mixed bonus");
    });

    it("should money come to multisig", async function() {
        let balance = web3.eth.getBalance(accounts[2]).sub(initialMultisigBalance);
        assert.equal(balance.toNumber(), web3.toWei(29100, 'ether'));
    });

    it("should buy with 2 borders crossing", async function() {
        await web3.eth.sendTransaction({from: accounts[2], to: saleContract.address, value: web3.toWei(70000, 'ether')});
        //We have now crossed 17, 15 and 12 bonus intervals.
        assert.equal(12, (await saleContract.getCurrentBonus()).toNumber(), "We should be at 12% bonus now");

        let balance = await tokenContract.balanceOf(accounts[2]);
        let base = zeroesBN.mul(web3.toWei(70000, 'ether')).div(web3.toWei(0.0025, 'ether'));

        let resulting_bonus = balance.sub(base).div(base).toNumber()*100;
        assert.ok(12 < resulting_bonus && resulting_bonus < 17, "There should be mixed bonus with these tokens");
    });

    it("should not exceed the cap", async function() {
        await testRpc.assertThrow('ico buy should have thrown', async () => {
            await saleContract.buy(accounts[0], {value: web3.toWei(230000, 'ether')});
        });
    });

    it("should not be able to transfer", async function() {
        await testRpc.assertThrow('token transfer should have thrown', async () => {
            await tokenContract.transfer(accounts[3], web3.toWei(10, 'ether'));
        });
    });

    it("should not be able to finalize for non-owner", async function() {
        await testRpc.assertThrow('token transfer should have thrown', async () => {
            await saleContract.finalize();
        });
    });

    it("should be able to finalize", async function() {
        let prevBalance = await tokenContract.balanceOf(accounts[2]);

        await saleContract.finalize({from: accounts[2]});
        assert.ok(prevBalance.lt(await tokenContract.balanceOf(accounts[2])), 'The rest of tokens should go to multisig');

        let total = await tokenContract.totalSupply();
        assert.equal(total.toNumber(), 200*1000*1000*zeroes, 'All the tokens should have been minted to cap')
    });

    it("should transfer be enabled by owner", async function() {
        await tokenContract.enableTransfer(true, {from: accounts[2]});
        assert.ok(await tokenContract.transferEnabled(), 'Transfer should have been enabled');
    });

    it("should transfer succeed", async function() {
        let prevBalance = await tokenContract.balanceOf(accounts[3]);
        await tokenContract.transfer(accounts[3], web3.toWei(10, 'ether'));
        let newBalance = await tokenContract.balanceOf(accounts[3]);

        assert.ok(prevBalance.add(web3.toWei(10, 'ether')).toNumber(), newBalance.toNumber(), 'Tokens should have been transferred');
    });
});
