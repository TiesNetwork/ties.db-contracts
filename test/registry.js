const TieToken = artifacts.require("./TieToken.sol");
const Registry = artifacts.require("./Registry.sol");
const TiesDB = artifacts.require("./TiesDB.sol");
const NoRestrictions = artifacts.require("../contracts/test/NoRestrictions.sol");

const logger = require('./helpers/logger');

const testRpc = require('./helpers/testRpc');
const eu = require("ethereumjs-util");

const db = require('./helpers/db');
const getHash = db.getHash;
const getTableHash = db.getTableHash;

const acc = require('./helpers/accounts');
const getAccounts = acc.getAccounts;
const getSecret = acc.getSecret;

const tok = require('./helpers/tokens');
const asTokens = tok.asTokens;

const getTiesDB = (() => {
    if(process.env.TRUFFLE_TEST_TIESDB_ADDR) {
        return async () => await TiesDB.at(process.env.TRUFFLE_TEST_TIESDB_ADDR);
    } else {
        return async () => undefined;
    }
})();

contract('Registry', async function (clientAccounts) {

    let tokenContract;
    let registry;
    let tiesDB;
    let accounts;

    debugger;

    //Cheque should be web3 BigNumber
    const cheque1 = asTokens(8);

    before(async function() {
        
        accounts = await getAccounts(clientAccounts[0], 4);

        tokenContract = await TieToken.new(accounts[3]);
        logger.info("TieToken.address = " + tokenContract.address);
        await tokenContract.setMinter(accounts[0], {from: accounts[3]});
        logger.info("TieToken.minter = " + accounts[0]);
        await tokenContract.enableTransfer(true, {from: accounts[3]});

        await Promise.all([
            tokenContract.mint(accounts[0], asTokens(1000), {from: accounts[0]}),
            tokenContract.mint(accounts[1], asTokens(2000), {from: accounts[0]}),
            tokenContract.mint(accounts[2], asTokens(5000), {from: accounts[0]}),
        ]);
        let tiesDBsame = await getTiesDB();
        tiesDB = tiesDBsame || await TiesDB.new();
        logger.info("TiesDB.address = " + tiesDB.address);
        registry = await Registry.new(tokenContract.address, tiesDB.address);
        logger.info("Registry.address = " + registry.address);

        await tokenContract.approve(registry.address, asTokens(1000), {from: accounts[0]});
        await tokenContract.approve(registry.address, asTokens(2000), {from: accounts[1]});
        await tokenContract.approve(registry.address, asTokens(2000), {from: accounts[2]});

        if(tiesDBsame !== tiesDB) {
            await tiesDB.setRegistry(registry.address);
        }
    });

    it("should users add deposits by transfer", async function () {
        await tokenContract.transfer(registry.address, asTokens(100), {from: accounts[0]});
        let dep = await registry.getUserDeposit(accounts[0]);

        assert.equal(dep.toString(), asTokens(100).toString(), "100 wasn't in the first account (ERC23)");
    });

    it("should users add deposits by function", async function () {
        await registry.addUserDeposit(asTokens(200), {from: accounts[1]});
        dep = await registry.getUserDeposit(accounts[1]);

        assert.equal(dep.toString(), asTokens(200).toString(), "200 wasn't in the second account (ERC20)");
    });

    it("should node add deposits", async function () {
        // Почему-то оверлоад фейлится :(
        // await callOverloadedTransfer(tokenContract, registry.address, 500*zeroes, "0x00000001", {from: accounts[2]});
        await tokenContract.transferAndPay(registry.address, asTokens(500), "0x00000001", {from: accounts[2]});
        let dep = await registry.getNodeDeposit(accounts[2]);

        assert.equal(dep.toString(), asTokens(500).toString(), "500 wasn't in the node account (ERC23)");
        
        await registry.addNodeDeposit(asTokens(200), {from: accounts[2]});
        dep = await registry.getNodeDeposit(accounts[2]);

        assert.equal(dep.toString(), asTokens(700).toString(), "700 wasn't in the node account (ERC20)");
    });

    it("should pay with cheque", async function() {
        let issuer = eu.setLength(eu.toBuffer(accounts[0]), 20);
        let beneficiary = eu.setLength(eu.toBuffer(accounts[2]), 20);
        let amount = eu.setLength(eu.toBuffer(new eu.BN(cheque1.toString())), 32);
        let timestamp = eu.setLength(eu.toBuffer(new eu.BN(0x12345678)), 8);
        let sha3hash = eu.sha3(Buffer.concat([eu.toBuffer("TIE cheque"), issuer, beneficiary, amount, timestamp]));
        let sig = eu.ecsign(sha3hash, eu.toBuffer(getSecret(0)));

        logger.trace("cashCheque(" + accounts[0] + ", " + accounts[2] + ", " + cheque1 + ", " + web3.utils.toBN(0x12345678) + ", " + eu.bufferToHex(sig.v) + ", " + eu.bufferToHex(sig.r) + ", " + eu.bufferToHex(sig.s) + ")");

        let tx = await registry.cashCheque(accounts[0], accounts[2], cheque1, web3.utils.toBN(0x12345678), eu.bufferToHex(sig.v), eu.bufferToHex(sig.r), eu.bufferToHex(sig.s));

        let events = tx.logs;
        let ok = events.find(e => e.event == 'ChequeRedeemed');

        assert.isOk(ok, 'paying with check should have been successful!');

        // Check payment is done

        let deposit = await registry.getUserDeposit(accounts[0]);

        assert.equal(deposit.toString(), asTokens(100 - 8).toString(), "Deposit should have decreased");

        let sent = await registry.getSent(accounts[0], accounts[2]);

        assert.equal(sent.toString(), cheque1.toString(), "Amount should have been sent");

        let balance = await tokenContract.balanceOf(accounts[2]);

        assert.equal(balance.toString(), asTokens(4300 + 8).toString(), "Amount should have been received");
    });

});

contract('Registry - TiesDB', async function (clientAccounts) {
    let tokenContract;
    let registry;
    let tiesDB;
    let noRestrictions;
    let accounts;

    debugger;

    before(async function(){

        accounts = await getAccounts(clientAccounts[0], 7);

        tokenContract = await TieToken.new(accounts[3]);
        logger.info("TieToken.address = " + tokenContract.address);
        await tokenContract.setMinter(accounts[0], {from: accounts[3]});
        logger.info("TieToken.minter = " + accounts[0]);
        await tokenContract.enableTransfer(true, {from: accounts[3]});

        await Promise.all([
            tokenContract.mint(accounts[0], asTokens(1000), {from: accounts[0]}),
            tokenContract.mint(accounts[1], asTokens(2000), {from: accounts[0]}),
            tokenContract.mint(accounts[2], asTokens(5000), {from: accounts[0]}),
            tokenContract.mint(accounts[3], asTokens(5000), {from: accounts[0]}),
            tokenContract.mint(accounts[4], asTokens(5000), {from: accounts[0]}),
            tokenContract.mint(accounts[5], asTokens(5000), {from: accounts[0]}),
            tokenContract.mint(accounts[6], asTokens(5000), {from: accounts[0]}),
        ]);
        let tiesDBsame = await getTiesDB();
        tiesDB = tiesDBsame || await TiesDB.new();
        logger.info("TiesDB.address = " + tiesDB.address);
        registry = await Registry.new(tokenContract.address, tiesDB.address);
        logger.info("Registry.address = " + registry.address);

        if(tiesDBsame !== tiesDB) {
            await tiesDB.setRegistry(registry.address);
        }

        noRestrictions = await NoRestrictions.new()
    });

    it("should register nodes", async function () {
        await Promise.all([
            tokenContract.transferAndPay(registry.address, asTokens(500), "0x00000001", {from: accounts[3]}),
            tokenContract.transferAndPay(registry.address, asTokens(500), "0x00000001", {from: accounts[4]}),
            tokenContract.transferAndPay(registry.address, asTokens(500), "0x00000001", {from: accounts[5]}),
            tokenContract.transferAndPay(registry.address, asTokens(500), "0x00000001", {from: accounts[6]}),
        ]);

        let nodes = await tiesDB.getNodes();
        assert.equal(nodes.length, 4, "There should be 4 nodes by now");
    });

    it("should create table", async function () {
        await tiesDB.createTablespace("tblspc", noRestrictions.address);
        await tiesDB.createTable(getHash("tblspc"), "tbl");

        let exists = await tiesDB.hasTable(getTableHash("tblspc", "tbl"));
        assert.ok(exists, "Table should exist now");
    });

    it("should distribute", async function () {
        let tblHash = getTableHash("tblspc", "tbl");
        await tiesDB.createField(tblHash, "field1", "type", "0x");

        await testRpc.assertThrow('should not distribute table if there is no primary index', async () => {
            await tiesDB.distribute(tblHash, 2, 2);
        });

        await testRpc.assertThrow('should not distribute table if there are no nodes in queue', async () => {
            await tiesDB.distribute(tblHash, 5, 3);
        });

        await registry.acceptRanges(true, {from: accounts[3]}),
        await registry.acceptRanges(true, {from: accounts[5]}),
        await registry.acceptRanges(true, {from: accounts[6]}),

        await testRpc.assertThrow('should not distribute table if there are not enough nodes in queue', async () => {
            await tiesDB.distribute(tblHash, 5, 4);
        });

        await tiesDB.createIndex(tblHash, "key", 1, [getHash("field1")]);
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