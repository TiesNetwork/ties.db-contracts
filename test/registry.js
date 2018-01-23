let TieToken = artifacts.require("./TieToken.sol");
let Registry = artifacts.require("./Registry.sol");
let TiesDB = artifacts.require("./TiesDB.sol");
let NoRestrictions = artifacts.require("../contracts/test/NoRestrictions.sol");

const testRpc = require('./helpers/testRpc');
let EU = require("ethereumjs-util");

const Db = require('./helpers/db');

let secrets = [
    "0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3", //accounts[0]
    "0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f", //accounts[1]
    "0x0dbbe8e4ae425a6d2687f1a7e3ba17bc98c673636790f1b8ad91193c05875ef1", //accounts[2]
    "0xc88b703fb08cbea894b6aeff5a544fb92e78a18e19814cd85da83b71f772aa6c", //accounts[3]
];

const decimals = 18;
const zeroes = Math.pow(10, decimals);
const zeroesBN = web3.toBigNumber(10).pow(web3.toBigNumber(decimals));

contract('Registry', async function (accounts) {
    let tokenContract;
    let registry;
    let tiesDB;

    debugger;

    //Cheque should be web3 BigNumber
    const cheque1 = web3.toBigNumber(8).mul(zeroesBN.toString());

    before(async function(){
        tokenContract = await TieToken.new(accounts[3]);
        await tokenContract.setMinter(accounts[0], {from: accounts[3]});
        await tokenContract.enableTransfer(true, {from: accounts[3]});

        await Promise.all([
            tokenContract.mint(accounts[0], 1000*zeroes),
            tokenContract.mint(accounts[1], 2000*zeroes),
            tokenContract.mint(accounts[2], 5000*zeroes),
        ]);

        tiesDB = await TiesDB.deployed();
        registry = await Registry.new(tokenContract.address, tiesDB.address);

        await tokenContract.approve(registry.address, 1000*zeroes, {from: accounts[0]});
        await tokenContract.approve(registry.address, 2000*zeroes, {from: accounts[1]});
        await tokenContract.approve(registry.address, 2000*zeroes, {from: accounts[2]});

        await tiesDB.setRegistry(registry.address);
    });

    it("should users add deposits", async function () {
        await tokenContract.transfer(registry.address, 100*zeroes);
        let dep = await registry.getUserDeposit(accounts[0]);

        assert.equal(dep.toNumber(), 100*zeroes, "100 wasn't in the first account (ERC23)");

        await registry.addUserDeposit(200*zeroes, {from: accounts[1]});
        dep = await registry.getUserDeposit(accounts[1]);

        assert.equal(dep.toNumber(), 200*zeroes, "200 wasn't in the second account (ERC20)");
    });

    it("should node add deposits", async function () {
        //Почему-то оверлоад фейлится :(
//        await callOverloadedTransfer(tokenContract, registry.address, 500*zeroes, "0x00000001", {from: accounts[2]});
        await tokenContract.transferAndPay(registry.address, 500*zeroes, "0x00000001", {from: accounts[2]});
        let dep = await registry.getNodeDeposit(accounts[2]);

        assert.equal(dep.toNumber(), 500*zeroes, "500 wasn't in the node account (ERC23)");

        await registry.addNodeDeposit(200*zeroes, {from: accounts[2]});
        dep = await registry.getNodeDeposit(accounts[2]);

        assert.equal(dep.toNumber(), 700*zeroes, "200 wasn't in the node account (ERC20)");
    });

    it("should pay with cheque", async function() {
        let issuer = EU.setLength(EU.toBuffer(accounts[0]), 20);
        let beneficiary = EU.setLength(EU.toBuffer(accounts[2]), 20);
        let amount = EU.setLength(EU.toBuffer(new EU.BN(cheque1.toString())), 32);
        let timestamp = EU.setLength(EU.toBuffer(new EU.BN(0x12345678)), 8);
        let sha3hash = EU.sha3(Buffer.concat([EU.toBuffer("TIE cheque"), issuer, beneficiary, amount, timestamp]));
        let sig = EU.ecsign(sha3hash, EU.toBuffer(secrets[0]));

        let tx = await registry.cashCheque(accounts[0], accounts[2], cheque1, web3.toBigNumber(0x12345678), EU.bufferToHex(sig.v), EU.bufferToHex(sig.r), EU.bufferToHex(sig.s));

        let events = tx.logs;
        let ok = events.find(e => e.event == 'ChequeRedeemed');

        assert.isOk(ok, 'paying with check should have been successful!');
    });

    it("should payment be done", async function() {
        let deposit = await registry.getUserDeposit(accounts[0]);

        assert.equal(deposit.toString(), (100 - 8)*zeroes, "Deposit should have decreased");

        let sent = await registry.getSent(accounts[0], accounts[2]);

        assert.equal(sent.toString(), cheque1.toString(), "Amount should have been sent");

        let balance = await tokenContract.balanceOf(accounts[2]);

        assert.equal(balance.toString(), (4300 + 8)*zeroes, "Amount should have been received");
    });
});

contract('Registry - TiesDB', async function (accounts) {
    let tokenContract;
    let registry;
    let tiesDB;
    let noRestrictions;

    debugger;

    before(async function(){
        tokenContract = await TieToken.new(accounts[3]);
        await tokenContract.setMinter(accounts[0], {from: accounts[3]});
        await tokenContract.enableTransfer(true, {from: accounts[3]});

        await Promise.all([
            tokenContract.mint(accounts[0], 1000*zeroes),
            tokenContract.mint(accounts[1], 2000*zeroes),
            tokenContract.mint(accounts[2], 5000*zeroes),
            tokenContract.mint(accounts[3], 5000*zeroes),
            tokenContract.mint(accounts[4], 5000*zeroes),
            tokenContract.mint(accounts[5], 5000*zeroes),
            tokenContract.mint(accounts[6], 5000*zeroes),
        ]);

        tiesDB = await TiesDB.deployed();
        registry = await Registry.new(tokenContract.address, tiesDB.address);
        await tiesDB.setRegistry(registry.address);

        noRestrictions = await NoRestrictions.new()
    });

    it("should register nodes", async function () {
        await Promise.all([
            tokenContract.transferAndPay(registry.address, 500*zeroes, "0x00000001", {from: accounts[3]}),
            tokenContract.transferAndPay(registry.address, 500*zeroes, "0x00000001", {from: accounts[4]}),
            tokenContract.transferAndPay(registry.address, 500*zeroes, "0x00000001", {from: accounts[5]}),
            tokenContract.transferAndPay(registry.address, 500*zeroes, "0x00000001", {from: accounts[6]}),
        ]);

        let nodes = await tiesDB.getNodes();
        assert.equal(nodes.length, 4, "There should be 4 nodes by now");
    });

    it("should create table", async function () {
        await tiesDB.createTablespace("tblspc", noRestrictions.address);
        await tiesDB.createTable(Db.getHash("tblspc"), "tbl");

        let exists = await tiesDB.hasTable(Db.getHash("tblspc"), Db.getTableHash("tblspc", "tbl"));
        assert.ok(exists, "Table should exist now");
    });

    it("should distribute", async function () {
        let tblHash = Db.getTableHash("tblspc", "tbl");

        await testRpc.assertThrow('should not distribute table if there are no nodes in queue', async () => {
            await tiesDB.distribute(tblHash, 5, 3);
        });

        await Promise.all([
            registry.acceptRanges(true, {from: accounts[3]}),
            registry.acceptRanges(true, {from: accounts[5]}),
            registry.acceptRanges(true, {from: accounts[6]}),
        ]);

        await testRpc.assertThrow('should not distribute table if there are not enough nodes in queue', async () => {
            await tiesDB.distribute(tblHash, 5, 4);
        });

        await tiesDB.distribute(tblHash, 2, 2);

        let ranges = await tiesDB.getNodeTableRanges(accounts[4], tblHash);
        assert.equal(ranges.length, 0, 'Inactive node should not receive ranges!');

        ranges = await tiesDB.getNodeTableRanges(accounts[3], tblHash);
        assert.equal(ranges.length, 2, 'First node should receive 2 ranges!');

        ranges = await tiesDB.getNodeTableRanges(accounts[5], tblHash);
        assert.equal(ranges.length, 1, 'Second node should receive 1 range!');
    });

});

async function callOverloadedTransfer(contract, to, value, data, params){
	const web3Abi = require('web3-eth-abi');
	const overloadedTransferAbi = {
        "constant": false,
        "inputs": [
            {
                "name": "to",
                "type": "address"
            },
            {
                "name": "value",
                "type": "uint256"
            },
            {
                "name": "data",
                "type": "bytes"
            }
        ],
        "name": "transfer",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    };

    const transferMethodTransactionData = web3Abi.encodeFunctionCall(
        overloadedTransferAbi,
        [
            to,
            value,
            data
        ]
    );
    
    return await web3.eth.sendTransaction({from: params.from, to: contract.address, data: transferMethodTransactionData, value: params.value || 0});
}