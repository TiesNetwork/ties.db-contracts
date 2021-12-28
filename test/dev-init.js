if(process.env.TRUFFLE_DEVELOPMENT_DEPLOY === undefined) {
    return;
}

const TieToken = artifacts.require("./TieToken.sol");
const Registry = artifacts.require("./Registry.sol");
const TiesDB = artifacts.require("./TiesDB.sol");
const NoRestrictions = artifacts.require("./test/NoRestrictions.sol");

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

contract('Development - TiesDB', async function (clientAccounts) {
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

    it("should register development nodes", async function () {
        await Promise.all([
            tokenContract.transferAndPay(registry.address, asTokens(500), "0x00000001", {from: accounts[3]}),
            tokenContract.transferAndPay(registry.address, asTokens(500), "0x00000001", {from: accounts[4]}),
            tokenContract.transferAndPay(registry.address, asTokens(500), "0x00000001", {from: accounts[5]}),
            tokenContract.transferAndPay(registry.address, asTokens(500), "0x00000001", {from: accounts[6]}),
        ]);

        let nodes = await tiesDB.getNodes();
        nodes.forEach((node, idx) => {
            logger.log("Node[" + idx + "]" + node);
        });
        assert.equal(nodes.length, 4, "There should be 4 nodes by now");
    });

    it("should create table client-dev.test", async function () {
        await tiesDB.createTablespace("client-dev.test", noRestrictions.address);
        await tiesDB.createTable(getHash("client-dev.test"), "all_types");

        let exists = await tiesDB.hasTable(getTableHash("client-dev.test", "all_types"));
        assert.ok(exists, "Table should exist now");
    });

    it("should distribute client-dev.test", async function () {
        let tblHash = getTableHash("client-dev.test", "all_types");
        await tiesDB.createField(tblHash, "fInteger", "Integer", "0x");
        await tiesDB.createField(tblHash, "fBoolean", "Boolean", "0x");
        await tiesDB.createField(tblHash, "fLong", "Long", "0x");
        await tiesDB.createField(tblHash, "fFloat", "Float", "0x");
        await tiesDB.createField(tblHash, "fDouble", "Double", "0x");
        await tiesDB.createField(tblHash, "fDecimal", "Decimal", "0x");
        await tiesDB.createField(tblHash, "fString", "String", "0x");
        await tiesDB.createField(tblHash, "fBinary", "Binary", "0x");
        await tiesDB.createField(tblHash, "fTime", "Time", "0x");
        await tiesDB.createField(tblHash, "fDuration", "Duration", "0x");
        await tiesDB.createField(tblHash, "Id", "UUID", "0x");

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

        await tiesDB.createIndex(tblHash, "Id", 1, [getHash("Id")]);
        await tiesDB.createIndex(tblHash, "idx_fstring", 4, [getHash("fString")]);
        await tiesDB.distribute(tblHash, 2, 2);

        let ranges = await tiesDB.getNodeTableRanges(accounts[4], tblHash);
        assert.equal(ranges.length, 0, 'Inactive node should not receive ranges!');

        ranges = await tiesDB.getNodeTableRanges(accounts[3], tblHash);
        assert.equal(ranges.length, 2, 'First node should receive 2 ranges!');

        ranges = await tiesDB.getNodeTableRanges(accounts[5], tblHash);
        assert.equal(ranges.length, 1, 'Second node should receive 1 range!');

        ranges = await tiesDB.getNodeTableRanges(accounts[6], tblHash);
        assert.equal(ranges.length, 1, 'Third node should receive 1 range!');

        let nodes = await tiesDB.getTableNodes(tblHash);
        assert.equal(nodes.length, 3, 'Third node should receive 1 range!');
    });

});
