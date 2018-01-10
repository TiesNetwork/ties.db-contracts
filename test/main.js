let TiesDB = artifacts.require("../contracts/structure/TiesDB.sol");
let NoRestrictions = artifacts.require("./helpers/NoRestrictions.sol");
const testRpc = require('./helpers/testRpc');

let secrets = [
    "0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3", //accounts[0]
    "0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f", //accounts[1]
    "0x0dbbe8e4ae425a6d2687f1a7e3ba17bc98c673636790f1b8ad91193c05875ef1", //accounts[2]
    "0xc88b703fb08cbea894b6aeff5a544fb92e78a18e19814cd85da83b71f772aa6c", //accounts[3]
];

function getHash(name){
    let hash = web3.sha3(name);
    let bn = web3.toAscii(hash);
//    console.log("Hash of " + name + ": " + hash + "; " + bn.toString(16));
    return bn;
}

function getTableHash(tblspc, tbl){
    let hash = web3.sha3(tblspc + '#' + tbl);
    let bn = web3.toAscii(hash);
//    console.log("Hash of " + name + ": " + hash + "; " + bn.toString(16));
    return bn;
}

contract('TiesDB (Tablespaces)', async function (accounts) {
    debugger;

    let tiesDB, noRestrictions;

    before(async function(){
        tiesDB = await TiesDB.deployed();
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
        tiesDB = await TiesDB.deployed();
        noRestrictions = await NoRestrictions.new();
        await tiesDB.createTablespace("tblspc", noRestrictions.address);
        hashTblspc = getHash("tblspc");
    });

    it("should not find inexistent table", async function () {
        let exists = await tiesDB.hasTable(hashTblspc, getTableHash("tblspc", "tbl"));
        assert.ok(!exists, "Table should not exist yet");
    });

    it("should create table", async function () {
        await tiesDB.createTable(hashTblspc, "tbl");

        let exists = await tiesDB.hasTable(hashTblspc, getTableHash("tblspc", "tbl"));
        assert.ok(exists, "Table should exist now");
    });

    it("should create other tables", async function () {
        await tiesDB.createTable(hashTblspc, "tbl2");

        let exists = await tiesDB.hasTable(hashTblspc, getTableHash("tblspc", "tbl2"));
        assert.ok(exists, "Table 2 should exist now");

        await tiesDB.createTable(hashTblspc, "tbl3");

        exists = await tiesDB.hasTable(hashTblspc, getTableHash("tblspc", "tbl3"));
        assert.ok(exists, "Table 3 should exist now");
    });

    it("should delete table", async function () {
        await tiesDB.deleteTable(hashTblspc, getTableHash("tblspc", "tbl2"));

        let exists = await tiesDB.hasTable(hashTblspc, getTableHash("tblspc", "tbl2"));
        assert.ok(!exists, "Table 2 should not exist now");

        exists = await tiesDB.hasTable(hashTblspc, getTableHash("tblspc", "tbl3"));
        assert.ok(exists, "Table 3 should still exist");
    });

    it("should delete last table", async function () {
        let hash = getTableHash("tblspc", "tbl3");
        await tiesDB.deleteTable(hashTblspc, hash);

        let exists = await tiesDB.hasTable(hashTblspc, hash);
        assert.ok(!exists, "Table 3 should not exist now");

        exists = await tiesDB.hasTable(hashTblspc, getTableHash("tblspc", "tbl"));
        assert.ok(exists, "First table should still exist");
    });
});

contract('TiesDB (Fields)', async function (accounts) {
    let tiesDB, noRestrictions, hashTblspc, hashTbl;

    before(async function(){
        tiesDB = await TiesDB.deployed();
        noRestrictions = await NoRestrictions.new();
        await tiesDB.createTablespace("tblspc", noRestrictions.address);
        hashTblspc = getHash("tblspc");
        await tiesDB.createTable(hashTblspc, "tbl");
        hashTbl = getTableHash("tblspc", "tbl");
    });

    it("should not find inexistent field", async function () {
        let exists = await tiesDB.hasField(hashTblspc, hashTbl, getHash("fld"));
        assert.ok(!exists, "Field should not exist yet");
    });

    it("should create field", async function () {
        await tiesDB.createField(hashTblspc, hashTbl, "fld", "type", "0x");

        let exists = await tiesDB.hasField(hashTblspc, hashTbl, getHash("fld"));
        assert.ok(exists, "Field should exist now");
    });

    it("should create other fields", async function () {
        await tiesDB.createField(hashTblspc, hashTbl, "fld2", "type", "0x");

        let exists = await tiesDB.hasField(hashTblspc, hashTbl, getHash("fld2"));
        assert.ok(exists, "Field 2 should exist now");

        await tiesDB.createField(hashTblspc, hashTbl, "fld3", "type", "0x");

        exists = await tiesDB.hasField(hashTblspc, hashTbl, getHash("fld3"));
        assert.ok(exists, "Field 3 should exist now");
    });

    it("should delete field", async function () {
        await tiesDB.deleteField(hashTblspc, hashTbl, getHash("fld2"));

        let exists = await tiesDB.hasField(hashTblspc, hashTbl, getHash("fld2"));
        assert.ok(!exists, "Field 2 should not exist now");

        exists = await tiesDB.hasField(hashTblspc, hashTbl, getHash("fld3"));
        assert.ok(exists, "Field 3 should still exist");
    });

    it("should delete last field", async function () {
        let hash = getHash("fld3");
        await tiesDB.deleteField(hashTblspc, hashTbl, hash);

        let exists = await tiesDB.hasField(hashTblspc, hashTbl, hash);
        assert.ok(!exists, "Field 3 should not exist now");

        exists = await tiesDB.hasField(hashTblspc, hashTbl, getHash("fld"));
        assert.ok(exists, "First field should still exist");
    });
});

contract('TiesDB (Triggers)', async function (accounts) {
    let tiesDB, noRestrictions, hashTblspc, hashTbl;

    before(async function(){
        tiesDB = await TiesDB.deployed();
        noRestrictions = await NoRestrictions.new();
        await tiesDB.createTablespace("tblspc", noRestrictions.address);
        hashTblspc = getHash("tblspc");
        await tiesDB.createTable(hashTblspc, "tbl");
        hashTbl = getTableHash("tblspc", "tbl");
    });

    it("should not find inexistent trigger", async function () {
        let exists = await tiesDB.hasTrigger(hashTblspc, hashTbl, getHash("trg"));
        assert.ok(!exists, "Trigger should not exist yet");
    });

    it("should create trigger", async function () {
        await tiesDB.createTrigger(hashTblspc, hashTbl, "trg", "0x");

        let exists = await tiesDB.hasTrigger(hashTblspc, hashTbl, getHash("trg"));
        assert.ok(exists, "Trigger should exist now");
    });

    it("should create other triggers", async function () {
        await tiesDB.createTrigger(hashTblspc, hashTbl, "trg2", "0x");

        let exists = await tiesDB.hasTrigger(hashTblspc, hashTbl, getHash("trg2"));
        assert.ok(exists, "Trigger 2 should exist now");

        await tiesDB.createTrigger(hashTblspc, hashTbl, "trg3", "0x");

        exists = await tiesDB.hasTrigger(hashTblspc, hashTbl, getHash("trg3"));
        assert.ok(exists, "Trigger 3 should exist now");
    });

    it("should delete trigger", async function () {
        await tiesDB.deleteTrigger(hashTblspc, hashTbl, getHash("trg2"));

        let exists = await tiesDB.hasTrigger(hashTblspc, hashTbl, getHash("trg2"));
        assert.ok(!exists, "Trigger 2 should not exist now");

        exists = await tiesDB.hasTrigger(hashTblspc, hashTbl, getHash("trg3"));
        assert.ok(exists, "Trigger 3 should still exist");
    });

    it("should delete last trigger", async function () {
        let hash = getHash("trg3");
        await tiesDB.deleteTrigger(hashTblspc, hashTbl, hash);

        let exists = await tiesDB.hasTrigger(hashTblspc, hashTbl, hash);
        assert.ok(!exists, "Trigger 3 should not exist now");

        exists = await tiesDB.hasTrigger(hashTblspc, hashTbl, getHash("trg"));
        assert.ok(exists, "First trigger should still exist");
    });
});
