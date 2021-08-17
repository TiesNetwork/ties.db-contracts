const TiesDB = artifacts.require("../contracts/structure/TiesDB.sol");
const NoRestrictions = artifacts.require("../contracts/test/NoRestrictions.sol");
const Registry = artifacts.require("./Registry.sol");
const TieToken = artifacts.require("./TieToken.sol");

const logger = require('./helpers/logger');

const testRpc = require('./helpers/testRpc');

const db = require('./helpers/db');
const getHash = db.getHash;
const getTableHash = db.getTableHash;

logger.info("web3.version: " + web3.version);

function asTokensDecimals(value, decimals) {
    return web3.utils.toBN(value).mul(web3.utils.toBN(10).pow(web3.utils.toBN(decimals)));
}

async function init(accounts){
    let tiesDB, noRestrictions, hashTblspc, hashTbl;
    tiesDB = await TiesDB.new();
    noRestrictions = await NoRestrictions.deployed();
    await tiesDB.createTablespace("tblspc", noRestrictions.address);
    hashTblspc = getHash("tblspc");
    await tiesDB.createTable(hashTblspc, "tbl");
    hashTbl = getTableHash("tblspc", "tbl");
    await tiesDB.createField(hashTbl, "fld1", "type", "0x");
    await tiesDB.createField(hashTbl, "fld2", "type1", "0x");
    await tiesDB.createField(hashTbl, "fld3", "type2", "0x");
    await tiesDB.createIndex(hashTbl, "index", 0x1, [getHash("fld1")]);
    token = await TieToken.deployed();
    async function asTokens(value) {
        return asTokensDecimals(value, await token.decimals());
    }
    registry = await Registry.new(token.address, tiesDB.address);
    await tiesDB.setRegistry(registry.address);
    await token.transferAndPay(registry.address, await asTokens(500), "0x00000001", {from: accounts[1]}),
    await token.transferAndPay(registry.address, await asTokens(500), "0x00000001", {from: accounts[2]}),
    await token.transferAndPay(registry.address, await asTokens(500), "0x00000001", {from: accounts[3]}),
    await registry.acceptRanges(true, {from: accounts[1]});
    await registry.acceptRanges(true, {from: accounts[2]});
    await registry.acceptRanges(true, {from: accounts[3]});
    return {tiesDB, noRestrictions, hashTblspc, hashTbl};
}

contract('TiesDB (distribute)', async function (accounts) {
    let tiesDB, noRestrictions, hashTblspc, hashTbl;

    before(async function() {
        ({tiesDB, noRestrictions, hashTblspc, hashTbl} = await init(accounts));
    });

    it("should distribute table", async function () {
        await tiesDB.distribute(hashTbl, 3, 1);
        let allNodes = await tiesDB.getNodes();
        let tableNodes = await tiesDB.getTableNodes(hashTbl);
        assert.ok(arrayEquals(allNodes, tableNodes), 'table should be distributed to all nodes');
    });
});
/**/

contract('TiesDB (displace)', async function (accounts) {
    let tiesDB, noRestrictions, hashTblspc, hashTbl;

    before(async function() {
        ({tiesDB, noRestrictions, hashTblspc, hashTbl} = await init(accounts));
    });

    it("should displace node", async function () {
        await tiesDB.distribute(hashTbl, 2, 1);
        let tableNodes = await tiesDB.getTableNodes(hashTbl);
        let deadNode = tableNodes[0];
        let displaced = await tiesDB.displaceNode(deadNode, {from: deadNode});
        assert.ok(displaced != deadNode, 'node was not displaced properly');
        let newTableNodes = await tiesDB.getTableNodes(hashTbl);
        //assert.fail('queue: '+(await tiesDB.getQueueHead())+' of '+(await tiesDB.getQueue())+'\n'+tableNodes+'\n'+newTableNodes);
        assert.ok(!newTableNodes.includes(deadNode), 'table should now be distributed to new node');
    });
});
/**/

function arrayEquals(source, array) {
    // if the other array is a falsy value, return
    if (!source || !array)
        return false;

    // compare lengths - can save a lot of time
    if (source.length != array.length)
        return false;

    for (var i = 0, l=source.length; i < l; i++) {
        // Check if we have nested arrays
        if (source[i] instanceof Array && array[i] instanceof Array) {
            // recurse into the nested arrays
            if (!arrayEquals(source[i], array[i]))
                return false;
        }
        else if (source[i] != array[i]) {
            // Warning - two different object instances will never be equal: {x:20} != {x:20}
            return false;
        }
    }
    return true;
}

function arrayIncludes(source, array) {
    // if the other array is a falsy value, return
    if (!source || !array)
        return false;

    // compare lengths - can save a lot of time 
    if (source.length < array.length)
        return false;

    for (var i = 0, l=array.length; i < l; i++) {
        if (!source.includes(array[i])) {
            return false;
        }
    }
    return true;
}