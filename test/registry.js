let TieToken = artifacts.require("./TieToken.sol");
let Registry = artifacts.require("./Registry.sol");
const testRpc = require('./helpers/testRpc');
let EU = require("ethereumjs-util");


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

    debugger;

    //Cheque should be web3 BigNumber
    const cheque1 = web3.toBigNumber(8).mul(zeroesBN.toString());

    before(async function(){
        tokenContract = await TieToken.new(accounts[3]);
        await tokenContract.setMinter(accounts[0], {from: accounts[3]});
        await tokenContract.enableTransfer(true, {from: accounts[3]});

        await tokenContract.mint(accounts[0], 1000*zeroes);
        await tokenContract.mint(accounts[1], 2000*zeroes);
        await tokenContract.mint(accounts[2], 5000*zeroes);

        registry = await Registry.new(tokenContract.address);

        await tokenContract.approve(registry.address, 1000*zeroes, {from: accounts[0]});
        await tokenContract.approve(registry.address, 2000*zeroes, {from: accounts[1]});
        await tokenContract.approve(registry.address, 2000*zeroes, {from: accounts[2]});
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
        await callOverloadedTransfer(tokenContract, registry.address, 500*zeroes, "0x00000001", {from: accounts[2]});
//        await tokenContract.transferAndPay(registry.address, 500*zeroes, "0x00000001", {from: accounts[2]});
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

async function callOverloadedTransfer(contract, to, value, data, params){
	const web3Abi = require('web3-eth-abi');
	const overloadedTransferAbi = {
    	"constant": false,
    	"inputs": [
            {
                "name": "_to",
                "type": "address"
            },
            {
                "name": "_value",
                "type": "uint256"
            },
            {
                "name": "_data",
                "type": "bytes"
            }
    	],
    	"name": "transfer",
    	"outputs": [
        	{
           		"name": "",
            	"type": "bool"
        	}
    	],
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