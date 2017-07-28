let TieToken = artifacts.require("./TieToken.sol");
let Registry = artifacts.require("./Registry.sol");
let Invitation = artifacts.require("./Invitation.sol");
var EU = require("ethereumjs-util");

const decimals = 18;
const zeroes = Math.pow(10, decimals);
const zeroesBN = (new EU.BN(10)).pow(new EU.BN(decimals));

let secrets = [
    "0x83c14ddb845e629975e138a5c28ad5a72a49252ea65b3d3ec99810c82751cc3a", //accounts[0]
    "0x52f3a1fa15405e1d5a68d7774ca45c7a3c7373a66c3c44db94a7f99a22c14d28", //accounts[1]
    "0xdc6a7f0cd30f86da5e55ca7b62ac1a86f5d8b76a796176152803e0fcbc253900", //accounts[2]
    "0xd3b6b98613ce7bd4636c5c98cc17afb0403d690f9c2b646726e08334583de101", //accounts[3]
];

contract('Registry', async function (accounts) {
    let tokenContract;
    let registry;

    const cheque1 = zeroesBN.mul(new EU.BN(8));

    before(async function(){
        tokenContract = await TieToken.new(accounts[3]);
        await tokenContract.setMinter(accounts[0], {from: accounts[3]});
        await tokenContract.enableTransfer(true, {from: accounts[3]});

        await tokenContract.mint(accounts[0], 1000*zeroes);
        await tokenContract.mint(accounts[1], 2000*zeroes);

        registry = await Registry.new(tokenContract.address);

        await tokenContract.approve(registry.address, 1000*zeroes, {from: accounts[0]});
        await tokenContract.approve(registry.address, 2000*zeroes, {from: accounts[1]});
    });

    it("should add deposits", async function () {
        await tokenContract.transfer(registry.address, 100*zeroes);
        let dep = await registry.getDeposit(accounts[0]);

        assert.equal(dep.toNumber(), 100*zeroes, "100 wasn't in the first account (ERC23)");

        await registry.addDeposit(200*zeroes, {from: accounts[1]});
        dep = await registry.getDeposit(accounts[1]);

        assert.equal(dep.toNumber(), 200*zeroes, "200 wasn't in the second account (ERC20)");
    });

    it("should pay with cheque", async function() {
        let issuer = EU.setLength(EU.toBuffer(accounts[0]), 20);
        let beneficiary = EU.setLength(EU.toBuffer(accounts[2]), 20);
        let amount = EU.setLength(EU.toBuffer(cheque1), 32);
        let sha3hash = EU.sha3(Buffer.concat([EU.toBuffer("TIE cheque"), issuer, beneficiary, amount]));
        let sig = EU.ecsign(sha3hash, EU.toBuffer(secrets[0]));

        let tx = await registry.cashCheque(accounts[0], accounts[2], cheque1, EU.bufferToHex(sig.v), EU.bufferToHex(sig.r), EU.bufferToHex(sig.s));

        let events = tx.logs;
        let ok = events.find(e => e.event == 'ChequeRedeemed');

        assert.isOk(ok, 'paying with check should have been successful!');
    });

    it("should payment be done", async function() {
        let deposit = await registry.getDeposit(accounts[0]);

        assert.equal(deposit.toString(), (100 - 8)*zeroes, "Deposit should have decreased");

        let sent = await registry.getSent(accounts[0], accounts[2]);

        assert.equal(sent.toString(), cheque1.toString(), "Amount should have been sent");

        let balance = await tokenContract.balanceOf(accounts[2]);

        assert.equal(balance.toString(), cheque1.toString(), "Amount should have been received");

    });

});

contract('Invitation', async function (accounts) {
    let tokenContract;
    let invitation;

    before(async function(){
        tokenContract = await TieToken.new(accounts[3]);
        await tokenContract.setMinter(accounts[0], {from: accounts[3]});
        await tokenContract.enableTransfer(true, {from: accounts[3]});

        await tokenContract.mint(accounts[0], 1000*zeroes);
        await tokenContract.mint(accounts[1], 2000*zeroes);

        invitation = await Invitation.new(tokenContract.address);
    });

    it("should issue invitation", async function () {
        await tokenContract.transferAndPay(invitation.address, 10*zeroes, null, {value: web3.toWei(0.1, 'ether')});

        let index = await invitation.getLastInvite(accounts[0]);

        assert.equal(index.toNumber(), 1, "The invite should have been issued!");

        let ok = await invitation.isInvitationAvailable(accounts[0], 1);

        assert.ok(ok, "The issued invitation should be available");

        let balance = web3.eth.getBalance(invitation.address);

        assert.equal(balance.toString(), web3.toWei(0.1, 'ether').toString(), "The ether should have been transferred to invitation contract");

    });

    it("should redeem invitation", async function() {
        let index = EU.setLength(EU.toBuffer(new EU.BN(1)), 32);
        let sha3hash = EU.sha3(Buffer.concat([EU.toBuffer("TIE invitation"), index]));
        let sig = EU.ecsign(sha3hash, EU.toBuffer(secrets[0]));

        let oldBalance = web3.eth.getBalance(accounts[2]);

        let tx = await invitation.redeem(accounts[2], accounts[0], 1, EU.bufferToHex(sig.v), EU.bufferToHex(sig.r), EU.bufferToHex(sig.s));

        let events = tx.logs;
        let ok = events.find(e => e.event == 'Invited');
        assert.isOk(ok, 'invite redeem should have been successful!');

        let tokens = await tokenContract.balanceOf(accounts[2]);
        assert.equal(tokens.toNumber(), 10*zeroes, 'Tokens should have come from inviter');

        let newBalance = web3.eth.getBalance(accounts[2]);
        assert.equal(oldBalance.toNumber(), newBalance.sub(web3.toWei(0.1, 'ether')).toNumber(), 'Ether should have come from inviter');

    });

    it("should invitation have gone", async function() {
        let ok = await invitation.isInvitationAvailable(accounts[0], 1);

        assert.ok(!ok, "The issued invitation should have gone");
    });

    it("should withdraw invitation", async function () {
        let oldBalance = web3.eth.getBalance(accounts[0]);
        let oldTokens = await tokenContract.balanceOf(accounts[2]);
        let gp = web3.eth.gasPrice;

        let tx0 = await tokenContract.transferAndPay(invitation.address, 15*zeroes, null, {value: web3.toWei(0.2, 'ether')});
        let index = await invitation.getLastInvite(accounts[0]);

        assert.equal(index.toNumber(), 2, "The second invite should have been issued!");

        let indexbuf = EU.setLength(EU.toBuffer(new EU.BN(2)), 32);
        let sha3hash = EU.sha3(Buffer.concat([EU.toBuffer("TIE invitation"), indexbuf]));
        let sig = EU.ecsign(sha3hash, EU.toBuffer(secrets[0]));

        let tx = await invitation.redeem(accounts[0], accounts[0], index, EU.bufferToHex(sig.v), EU.bufferToHex(sig.r), EU.bufferToHex(sig.s));

        let events = tx.logs;
        let ok = events.find(e => e.event == 'InviteDeleted');
        assert.isOk(ok, 'invite withdraw should have been successful!');

        let newBalance = web3.eth.getBalance(accounts[0]);
        //Balance will diminish by gas used
        assert.ok(oldBalance.sub(newBalance).lt(web3.toWei(0.02, 'ether')), 'Ether should have returned to inviter');

        let newTokens = await tokenContract.balanceOf(accounts[2]);
        assert.equal(oldTokens.toNumber(), newTokens.toNumber(), 'Tokens should have returned to inviter');
    });
});
