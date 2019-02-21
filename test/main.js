let TiesDB = artifacts.require("../contracts/structure/TiesDB.sol");
let NoRestrictions = artifacts.require("../contracts/test/NoRestrictions.sol");

const logger = require('./helpers/logger');

const testRpc = require('./helpers/testRpc');

const db = require('./helpers/db');
const getHash = db.getHash;
const getTableHash = db.getTableHash;

logger.info("web3.version: " + web3.version);

contract('TiesDB (Tablespaces)', async function (accounts) {
    debugger;

    let tiesDB, noRestrictions;

    before(async function(){
        tiesDB = await TiesDB.new();
        noRestrictions = await NoRestrictions.new();
    });

    it("should not find inexistent tablespace", async function () {
        let exists = await tiesDB.hasTablespace(getHash("tblspc"));
        assert.ok(!exists, "Table space should not exist yet");
    });

    it("should create tablespace", async function () {
        await tiesDB.createTablespace("tblspc", noRestrictions.address);

        let exists = await tiesDB.hasTablespace(getHash("tblspc"));
        assert.ok(exists, "Table space should exist now");
    });

    it("should create other tablespaces", async function () {
        await tiesDB.createTablespace("tblspc2", noRestrictions.address);

        let exists = await tiesDB.hasTablespace(getHash("tblspc2"));
        assert.ok(exists, "Table space 2 should exist now");

        await tiesDB.createTablespace("tblspc3", noRestrictions.address);

        exists = await tiesDB.hasTablespace(getHash("tblspc3"));
        assert.ok(exists, "Table space 3 should exist now");
    });

    it("should delete tablespace", async function () {
        let hash = getHash("tblspc2");
        await tiesDB.deleteTablespace(hash);

        let exists = await tiesDB.hasTablespace(hash);
        assert.ok(!exists, "Table space 2 should not exist now");

        exists = await tiesDB.hasTablespace(getHash("tblspc3"));
        assert.ok(exists, "Table space 3 should still exist");
    });

    it("should delete last tablespace", async function () {
        let hash = getHash("tblspc3");
        await tiesDB.deleteTablespace(hash);

        let exists = await tiesDB.hasTablespace(hash);
        assert.ok(!exists, "Table space 3 should not exist now");

        exists = await tiesDB.hasTablespace(getHash("tblspc"));
        assert.ok(exists, "First table space should still exist");
    });
});

contract('TiesDB (Tables)', async function (accounts) {
    let tiesDB, noRestrictions, hashTblspc;

    before(async function(){
        tiesDB = await TiesDB.new();
        noRestrictions = await NoRestrictions.new();
        await tiesDB.createTablespace("tblspc", noRestrictions.address);
        let exists = await tiesDB.hasTablespace(getHash("tblspc"));
        assert.ok(exists, "Tablespace was not created");
        hashTblspc = getHash("tblspc");
    });

    it("should not find inexistent table", async function () {
        let exists = await tiesDB.hasTable(getTableHash("tblspc", "tbl"));
        assert.ok(!exists, "Table should not exist yet");
    });

    it("should create table", async function () {
        await tiesDB.createTable(hashTblspc, "tbl");

        let exists = await tiesDB.hasTable(getTableHash("tblspc", "tbl"));
        assert.ok(exists, "Table should exist now");
    });

    it("should create other tables", async function () {
        await tiesDB.createTable(hashTblspc, "tbl2");

        let exists = await tiesDB.hasTable(getTableHash("tblspc", "tbl2"));
        assert.ok(exists, "Table 2 should exist now");

        await tiesDB.createTable(hashTblspc, "tbl3");

        exists = await tiesDB.hasTable(getTableHash("tblspc", "tbl3"));
        assert.ok(exists, "Table 3 should exist now");

        let tsKey = await tiesDB.tableToTablespace(getTableHash("tblspc", "tbl3"));
        assert.equal(tsKey, hashTblspc, "We should be able to recover tablespace id from table id");
    });

    it("should delete table", async function () {
        await tiesDB.deleteTable(getTableHash("tblspc", "tbl2"));

        let exists = await tiesDB.hasTable(getTableHash("tblspc", "tbl2"));
        assert.ok(!exists, "Table 2 should not exist now");

        exists = await tiesDB.hasTable(getTableHash("tblspc", "tbl3"));
        assert.ok(exists, "Table 3 should still exist");

        let tsKey = await tiesDB.tableToTablespace(getTableHash("tblspc", "tbl2"));
        assert.ok(web3.utils.toBN(tsKey).eq(web3.utils.toBN(0)), "Deleted table id should be removed from mapping");
    });

    it("should delete last table", async function () {
        let hash = getTableHash("tblspc", "tbl3");
        await tiesDB.deleteTable(hash);

        let exists = await tiesDB.hasTable(hash);
        assert.ok(!exists, "Table 3 should not exist now");

        exists = await tiesDB.hasTable(getTableHash("tblspc", "tbl"));
        assert.ok(exists, "First table should still exist");
    });
});

contract('TiesDB (Fields)', async function (accounts) {
    let tiesDB, noRestrictions, hashTblspc, hashTbl;

    before(async function(){
        tiesDB = await TiesDB.new();
        noRestrictions = await NoRestrictions.new();
        await tiesDB.createTablespace("tblspc", noRestrictions.address);
        hashTblspc = getHash("tblspc");
        await tiesDB.createTable(hashTblspc, "tbl");
        hashTbl = getTableHash("tblspc", "tbl");
    });

    it("should not find inexistent field", async function () {
        let exists = await tiesDB.hasField(hashTbl, getHash("fld"));
        assert.ok(!exists, "Field should not exist yet");
    });

    it("should create field", async function () {
        await tiesDB.createField(hashTbl, "fld", "type", "0x");

        let exists = await tiesDB.hasField(hashTbl, getHash("fld"));
        assert.ok(exists, "Field should exist now");
    });

    it("should create other fields", async function () {
        await tiesDB.createField(hashTbl, "fld2", "type", "0x");

        let exists = await tiesDB.hasField(hashTbl, getHash("fld2"));
        assert.ok(exists, "Field 2 should exist now");

        await tiesDB.createField(hashTbl, "fld3", "type", "0x");

        exists = await tiesDB.hasField(hashTbl, getHash("fld3"));
        assert.ok(exists, "Field 3 should exist now");
    });

    it("should delete field", async function () {
        await tiesDB.deleteField(hashTbl, getHash("fld2"));

        let exists = await tiesDB.hasField(hashTbl, getHash("fld2"));
        assert.ok(!exists, "Field 2 should not exist now");

        exists = await tiesDB.hasField(hashTbl, getHash("fld3"));
        assert.ok(exists, "Field 3 should still exist");
    });

    it("should delete last field", async function () {
        let hash = getHash("fld3");
        await tiesDB.deleteField(hashTbl, hash);

        let exists = await tiesDB.hasField(hashTbl, hash);
        assert.ok(!exists, "Field 3 should not exist now");

        exists = await tiesDB.hasField(hashTbl, getHash("fld"));
        assert.ok(exists, "First field should still exist");
    });
});

contract('TiesDB (Triggers)', async function (accounts) {
    let tiesDB, noRestrictions, hashTblspc, hashTbl;

    before(async function(){
        tiesDB = await TiesDB.new();
        noRestrictions = await NoRestrictions.new();
        await tiesDB.createTablespace("tblspc", noRestrictions.address);
        hashTblspc = getHash("tblspc");
        await tiesDB.createTable(hashTblspc, "tbl");
        hashTbl = getTableHash("tblspc", "tbl");
    });

    it("should not find inexistent trigger", async function () {
        let exists = await tiesDB.hasTrigger(hashTbl, getHash("trg"));
        assert.ok(!exists, "Trigger should not exist yet");
    });

    it("should create trigger", async function () {
        await tiesDB.createTrigger(hashTbl, "trg", "0x");

        let exists = await tiesDB.hasTrigger(hashTbl, getHash("trg"));
        assert.ok(exists, "Trigger should exist now");
    });

    it("should create other triggers", async function () {
        await tiesDB.createTrigger(hashTbl, "trg2", "0x");

        let exists = await tiesDB.hasTrigger(hashTbl, getHash("trg2"));
        assert.ok(exists, "Trigger 2 should exist now");

        await tiesDB.createTrigger(hashTbl, "trg3", "0x");

        exists = await tiesDB.hasTrigger(hashTbl, getHash("trg3"));
        assert.ok(exists, "Trigger 3 should exist now");
    });

    it("should delete trigger", async function () {
        await tiesDB.deleteTrigger(hashTbl, getHash("trg2"));

        let exists = await tiesDB.hasTrigger(hashTbl, getHash("trg2"));
        assert.ok(!exists, "Trigger 2 should not exist now");

        exists = await tiesDB.hasTrigger(hashTbl, getHash("trg3"));
        assert.ok(exists, "Trigger 3 should still exist");
    });

    it("should delete last trigger", async function () {
        let hash = getHash("trg3");
        await tiesDB.deleteTrigger(hashTbl, hash);

        let exists = await tiesDB.hasTrigger(hashTbl, hash);
        assert.ok(!exists, "Trigger 3 should not exist now");

        exists = await tiesDB.hasTrigger(hashTbl, getHash("trg"));
        assert.ok(exists, "First trigger should still exist");
    });
});

contract('TiesDB (Indexes)', async function (accounts) {
    let tiesDB, noRestrictions, hashTblspc, hashTbl;

    before(async function(){
        tiesDB = await TiesDB.new();
        noRestrictions = await NoRestrictions.new();
        await tiesDB.createTablespace("tblspc", noRestrictions.address);
        hashTblspc = getHash("tblspc");
        await tiesDB.createTable(hashTblspc, "tbl");
        hashTbl = getTableHash("tblspc", "tbl");
        await tiesDB.createField(hashTbl, "fld1", "type", "0x");
        await tiesDB.createField(hashTbl, "fld2", "type1", "0x");
        await tiesDB.createField(hashTbl, "fld3", "type2", "0x");
    });

    it("should not find inexistent index", async function () {
        let exists = await tiesDB.hasIndex(hashTbl, getHash("index"));
        assert.ok(!exists, "Index should not exist yet");
    });

    it("should not create index with bad params", async function () {
        await testRpc.assertThrow('should not create unknown index', async () => {
            await tiesDB.createIndex(hashTbl, "index", 0x3, [getHash("fld1")]);
        });

        await testRpc.assertThrow('should not create index without fields', async () => {
            await tiesDB.createIndex(hashTbl, "index", 0x1, []);
        });

        await testRpc.assertThrow('should not create index with wrong fields', async () => {
            await tiesDB.createIndex(hashTbl, "index", 0x1, [getHash("fld8")]);
        });
    });

    it("should create index", async function () {
        await tiesDB.createIndex(hashTbl, "index", 0x1, [getHash("fld1")]);

        let exists = await tiesDB.hasIndex(hashTbl, getHash("index"));
        assert.ok(exists, "Index should exist now");

        await testRpc.assertThrow('should not create another primary index', async () => {
            await tiesDB.createIndex(hashTbl, "index2", 0x1, [getHash("fld1")]);
        });
    });

    it("should create other indexes", async function () {
        await tiesDB.createIndex(hashTbl, "index2", 0x2, [getHash("fld2"), getHash("fld1")]);

        await testRpc.assertThrow('should not create index with the same name', async () => {
            await tiesDB.createIndex(hashTbl, "index2", 0x4, [getHash("fld1")]);
        });

        let exists = await tiesDB.hasIndex(hashTbl, getHash("index2"));
        assert.ok(exists, "Index 2 should exist now");

        await tiesDB.createIndex(hashTbl, "index3", 0x4, [getHash("fld3")]);

        exists = await tiesDB.hasIndex(hashTbl, getHash("index3"));
        assert.ok(exists, "Index 3 should exist now");
    });

    it("should delete index", async function () {
        await tiesDB.deleteIndex(hashTbl, getHash("index2"));

        let exists = await tiesDB.hasIndex(hashTbl, getHash("index2"));
        assert.ok(!exists, "Index 2 should not exist now");

        exists = await tiesDB.hasIndex(hashTbl, getHash("index3"));
        assert.ok(exists, "Index 3 should still exist");

        await testRpc.assertThrow('should not delete primary index', async () => {
            await tiesDB.deleteIndex(hashTbl, getHash("index"));
        });
    });

    it("should delete last index", async function () {
        let hash = getHash("index3");
        await tiesDB.deleteIndex(hashTbl, hash);

        let exists = await tiesDB.hasIndex(hashTbl, hash);
        assert.ok(!exists, "Index 3 should not exist now");

        exists = await tiesDB.hasIndex(hashTbl, getHash("index"));
        assert.ok(exists, "First index should still exist");
    });
});

/**/
