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

async function signPacked(account, ...args) {
    let hash = web3.utils.soliditySha3(...args);
    return await web3.eth.personal.sign(hash, account);
}

async function zipWith(a1, a2, f) {
    return await Promise.all(a1.map(async (x, i) => f(x, a2[i])));
}

async function init(accounts) {
    let tiesDB = await TiesDB.new();
    let noRestrictions = await NoRestrictions.deployed();
    await tiesDB.createTablespace("tblspc", noRestrictions.address);
    let hashTblspc = getHash("tblspc");
    await tiesDB.createTable(hashTblspc, "tbl");
    let hashTbl = getTableHash("tblspc", "tbl");
    await tiesDB.createField(hashTbl, "fld1", "type", "0x");
    await tiesDB.createIndex(hashTbl, "index", 0x1, [getHash("fld1")]);
    let token = await TieToken.deployed();
    async function asTokens(value) {
        return asTokensDecimals(value, await token.decimals());
    }
    let registry = await Registry.new(token.address, tiesDB.address);
    await tiesDB.setRegistry(registry.address);
    await token.transferAndPay(registry.address, await asTokens(500), "0x00000001", {from: accounts[1]}),
    await token.transferAndPay(registry.address, await asTokens(500), "0x00000001", {from: accounts[2]}),
    await token.transferAndPay(registry.address, await asTokens(500), "0x00000001", {from: accounts[3]}),
    await registry.acceptRanges(true, {from: accounts[1]});
    await registry.acceptRanges(true, {from: accounts[2]});
    await registry.acceptRanges(true, {from: accounts[3]});

    await token.mint(accounts[0], await asTokens(5000));
    await token.transferAndPay(registry.address, await asTokens(500), "0x00000000", {from: accounts[0]});

    await token.mint(accounts[4], await asTokens(5000));
    let ethAmount = web3.utils.toWei(web3.utils.toBN(100), 'ether');
    await web3.eth.sendTransaction({from: accounts[0], to: accounts[4], value: ethAmount});
    await token.transferAndPay(registry.address, await asTokens(500), "0x00000001", {from: accounts[4]});
    await registry.acceptRanges(true, {from: accounts[4]});

    return {tiesDB, noRestrictions, hashTblspc, hashTbl, registry, token};
}

contract('TiesDB (redeem)', async function (accounts) {
    let tiesDB, noRestrictions, hashTblspc, hashTbl, registry, token;

    before(async function() {
        ({tiesDB, noRestrictions, hashTblspc, hashTbl, registry, token} = await init(accounts));
    });

    it("should redeem operational", async function () {
        await tiesDB.distribute(hashTbl, 2, 2);
        let tableNodes = await tiesDB.getTableNodes(hashTbl);
        assert.equal(4, tableNodes.length, "Wrong distributed nodes amount");
        assert.equal(accounts[1], tableNodes[0], "Wrong node distributed");
        assert.equal(accounts[2], tableNodes[1], "Wrong node distributed");
        assert.equal(accounts[3], tableNodes[2], "Wrong node distributed");
        assert.equal(accounts[4], tableNodes[3], "Wrong node distributed");

        let session = "0xb0eeb7dc55d14f49bbde6aeb2de85807";

        try {
            let sig = await signPacked(accounts[0],
                { t: 'address', v: registry.address },
                { t: 'address', v: accounts[0] },
                { t: 'bytes16', v: session },
                { t: 'bytes32', v: hashTbl },
                { t: 'uint', v: 9 },
                { t: 'uint', v: 1 },
            );
            await tiesDB.redeemOperation(accounts[0], session, hashTbl, 10, 1, sig);
            assert.fail("Transaction should not be accepted");
        } catch (error) {
            assert.ok(undefined != error);
        }
        
        {
            let userDeposit = await registry.getUserDeposit(accounts[0]);
            console.log('  User deposit before: ', userDeposit.toString());

            let nodeBalances = await Promise.all(tableNodes.map(async node => {
                let nodeBalance = await token.balanceOf(node);
                console.log('  Node ', node, ' balance before: ', nodeBalance.toString());
                return nodeBalance;
            }));

            let sig = await signPacked(accounts[0],
                { t: 'address', v: registry.address },
                { t: 'address', v: accounts[0] },
                { t: 'bytes16', v: session },
                { t: 'bytes32', v: hashTbl },
                { t: 'uint', v: 10 },
                { t: 'uint', v: 1 },
            );
            let result = await tiesDB.redeemOperation(accounts[0], session, hashTbl, 10, 1, sig);
            console.log('  Gas used for redeeming: ', result.receipt.gasUsed);
            let userDepositAfter = await registry.getUserDeposit(accounts[0]);
            console.log('  User deposit after:  ', userDepositAfter.toString());

            let nodeBalancesDelta = await Promise.all(tableNodes.map(async (node, i) => {
                let nodeBalance = await token.balanceOf(node);
                console.log('  Node ', node, ' balance after: ', nodeBalance.toString());
                let delta = nodeBalance.sub(nodeBalances[i]);
                console.log('  Node ', node, ' balance delta: ', delta.toString());
                return delta;
            }));

            const userDepositDelta = userDepositAfter.sub(userDeposit);
            console.log('  User deposit delta:  ', userDepositDelta.toString());
            assert.ok(userDepositDelta.ltn(0), "User deposit should decrease after redeeming");

            const nodeBalancesDeltaTotal = nodeBalancesDelta.reduce((a, v) => a.iadd(v) );
            assert.ok(nodeBalancesDeltaTotal.gtn(0), "Node balance should increase after redeeming");
            assert.equal(userDepositDelta.neg().toString(), nodeBalancesDeltaTotal.toString(),
                "User deposit delta does not match all nodes balance delta");

            let crops, tokens, nonce;
            ({crops, tokens, nonce} = await tiesDB.getOperationRedeemed(accounts[0], session, hashTbl));
            assert.equal(10, crops.toString(), "Wrong crops amount redeemed");
            assert.equal(tokens.toString(), nodeBalancesDeltaTotal.toString(), "Wrong tokens amount redeemed");
            assert.equal(1, nonce.toString(), "Wrong crops nonce redeemed");
        }
        try {
            let sig = await signPacked(accounts[0],
                { t: 'address', v: registry.address },
                { t: 'address', v: accounts[0] },
                { t: 'bytes16', v: session },
                { t: 'bytes32', v: hashTbl },
                { t: 'uint', v: 10 },
                { t: 'uint', v: 2 },
            );
            await tiesDB.redeemOperation(accounts[0], session, hashTbl, 10, 2, sig);
            assert.fail("Transaction should not be accepted");
        } catch (error) {
            assert.ok(undefined != error);
        }
        try {
            let sig = await signPacked(accounts[0],
                { t: 'address', v: registry.address },
                { t: 'address', v: accounts[0] },
                { t: 'bytes16', v: session },
                { t: 'bytes32', v: hashTbl },
                { t: 'uint', v: 11 },
                { t: 'uint', v: 1 },
            );
            await tiesDB.redeemOperation(accounts[0], session, hashTbl, 11, 1, sig);
            assert.fail("Transaction should not be accepted");
        } catch (error) {
            assert.ok(undefined != error);
        }
        {
            let sig = await signPacked(accounts[0],
                { t: 'address', v: registry.address },
                { t: 'address', v: accounts[0] },
                { t: 'bytes16', v: session },
                { t: 'bytes32', v: hashTbl },
                { t: 'uint', v: 100 },
                { t: 'uint', v: 10 },
            );
            await tiesDB.redeemOperation(accounts[0], session, hashTbl, 100, 10, sig);
        }
        ({crops, tokens, nonce} = await tiesDB.getOperationRedeemed(accounts[0], session, hashTbl));
        assert.equal(100, crops, "Wrong crops amount redeemed");
        assert.equal(10, nonce, "Wrong crops nonce redeemed");
    });

});
/**/
