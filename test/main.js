let TieToken = artifacts.require("./TieToken.sol");
let UserRegistry = artifacts.require("./UserRegistry.sol");
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

contract('UserRegistry', async function (accounts) {
    let tokenContract;
    let userRegistry;

    const cheque1 = zeroesBN.mul(new EU.BN(8));

    before(async function(){
        tokenContract = await TieToken.new();
        await tokenContract.mint(accounts[0], 1000*zeroes);
        await tokenContract.mint(accounts[1], 2000*zeroes);

        userRegistry = await UserRegistry.new(tokenContract.address);

        await tokenContract.approve(userRegistry.address, 1000*zeroes, {from: accounts[0]});
        await tokenContract.approve(userRegistry.address, 2000*zeroes, {from: accounts[1]});
    });

    it("should add deposits", async function () {
        await userRegistry.addDeposit(100*zeroes);
        let dep = await userRegistry.getDeposit(accounts[0]);

        assert.equal(dep.toNumber(), 100*zeroes, "100 wasn't in the first account");

        await userRegistry.addDeposit(200*zeroes, {from: accounts[1]});
        dep = await userRegistry.getDeposit(accounts[1]);

        assert.equal(dep.toNumber(), 200*zeroes, "200 wasn't in the second account");
    });

    it("should pay with cheque", async function() {
        let issuer = EU.setLength(EU.toBuffer(accounts[0]), 20);
        let beneficiary = EU.setLength(EU.toBuffer(accounts[2]), 20);
        let amount = EU.setLength(EU.toBuffer(cheque1), 32);
        let sha3hash = EU.sha3(Buffer.concat([issuer, beneficiary, amount]));
        let sig = EU.ecsign(sha3hash, EU.toBuffer(secrets[0]));

        let tx = await userRegistry.cashCheque(accounts[0], accounts[2], cheque1, EU.bufferToHex(sig.v), EU.bufferToHex(sig.r), EU.bufferToHex(sig.s));

        let events = tx.logs;
        let ok = events.find(e => e.event == 'ChequeRedeemed');

        assert.isOk(ok, 'paying with check should have been successful!');
    });

    it("should payment be done", async function() {
        let deposit = await userRegistry.getDeposit(accounts[0]);

        assert.equal(deposit.toString(), (100 - 8)*zeroes, "Deposit should have decreased");

        let sent = await userRegistry.getSent(accounts[0], accounts[2]);

        assert.equal(sent.toString(), cheque1.toString(), "Amount should have been sent");

        let balance = await tokenContract.balanceOf(accounts[2]);

        assert.equal(balance.toString(), cheque1.toString(), "Amount should have been received");

    });

});
