const TLStorage = artifacts.require("./TLStorage.sol");
const TLPayments = artifacts.require("./TLPayments.sol");
const TLTable = artifacts.require("./TLTable.sol"); 
const TLTblspace = artifacts.require("./TLTblspace.sol");
const TLNode = artifacts.require("./TLNode.sol"); 
const TLRanges = artifacts.require("./TLRanges.sol"); 
const TiesDB = artifacts.require("./TiesDB.sol");
const Registry = artifacts.require("./Registry.sol");
const TieToken = artifacts.require("./TieToken.sol");

const NoRestrictions = artifacts.require("./NoRestrictions.sol");

function asTokensDecimals(value, decimals) {
    return web3.utils.toBN(value).mul(web3.utils.toBN(10).pow(web3.utils.toBN(decimals)));
}

function asWei(amount, unit) {
    return web3.utils.toWei(web3.utils.toBN(amount), unit);
}

module.exports = async function(deployer, network, accounts) {

  if(process.env.TRUFFLE_SKIP_MIGRATIONS === 'Y') {
    return;
  }

  deployer.deploy(TLRanges);
  deployer.link(TLRanges, TLNode);

  deployer.deploy(TLNode);
  deployer.link(TLNode, TLStorage);

  deployer.deploy(TLStorage);
  deployer.deploy(TLTable);
  deployer.deploy(TLTblspace);
  deployer.deploy(TLPayments);

  deployer.link(TLNode, TiesDB);
  deployer.link(TLStorage, TiesDB);
  deployer.link(TLTable, TiesDB);
  deployer.link(TLTblspace, TiesDB);
  deployer.link(TLPayments, TiesDB);

  deployer.then(function() {
    return deployer.deploy(TiesDB);
  }).then(function() {
    return deployer.deploy(TieToken, accounts[0]);
  }).then(function() {
    return deployer.deploy(Registry, TieToken.address, TiesDB.address);
  });

  deployer.deploy(NoRestrictions);

  {
    var tiesDBContract, registryContract;
    deployer.then(function(){
      return TiesDB.deployed();
    }).then(function(instance){
      tiesDBContract = instance;
    }).then(function(){
      return Registry.deployed();
    }).then(function(instance){
      registryContract = instance;
    }).then(async function(){
      await tiesDBContract.setRegistry(registryContract.address);
    });
  }

  {
    var tokenContract, registryContract;
    deployer.then(function(){
      return TieToken.deployed();
    }).then(function(instance){
      tokenContract = instance;
    }).then(function(){
      return Registry.deployed();
    }).then(function(instance){
      registryContract = instance;
    }).then(async function(){
      async function asTokens(value) {
        return asTokensDecimals(value, await tokenContract.decimals());
      }
      await tokenContract.enableTransfer(true);
      console.debug('Token transfer enabled: '+ await tokenContract.transferEnabled());
      await Promise.all([
        tokenContract.mint(accounts[1], await asTokens(5000)),
        tokenContract.mint(accounts[2], await asTokens(5000)),
        tokenContract.mint(accounts[3], await asTokens(5000)),
      ]);
      console.debug('Transfered tokens to nodes');
      const amount = asWei(100, 'ether');
      await Promise.all([
          await web3.eth.sendTransaction({from: accounts[0], to: accounts[1], value: amount}),
          await web3.eth.sendTransaction({from: accounts[0], to: accounts[2], value: amount}),
          await web3.eth.sendTransaction({from: accounts[0], to: accounts[3], value: amount}),
      ]);
      console.debug('Transfered ether to nodes');
      await Promise.all([
          tokenContract.transferAndPay(registryContract.address, await asTokens(500), "0x00000001", {from: accounts[1]}),
          tokenContract.transferAndPay(registryContract.address, await asTokens(500), "0x00000001", {from: accounts[2]}),
          tokenContract.transferAndPay(registryContract.address, await asTokens(500), "0x00000001", {from: accounts[3]}),
      ]);
      console.debug('Transfered tokens from nodes');
      await Promise.all([
        registryContract.acceptRanges(true, {from: accounts[1]}),
        registryContract.acceptRanges(true, {from: accounts[2]}),
        registryContract.acceptRanges(true, {from: accounts[3]}),
      ]);
      console.debug('Accepted ranges by nodes');
    });
  }

  deployer.then(function(){
    console.debug('');
  }).then(function(){
    return TiesDB.deployed();
  }).then(function(instance){
    console.log('        TiesDB: '+instance.address);
  }).then(function(){
    return NoRestrictions.deployed();
  }).then(function(instance){
    console.log('NoRestrictions: '+instance.address);
  }).then(function(instance){
    for(var i=1; i<=3; i++) {
      console.log('   Node['+i+']: '+accounts[i]);
    }
  })

};
