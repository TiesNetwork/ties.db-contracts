var TLStorage = artifacts.require("./TLStorage.sol");
var TLTable = artifacts.require("./TLTable.sol"); 
var TLTblspace = artifacts.require("./TLTblspace.sol");
var TLNode = artifacts.require("./TLNode.sol"); 
var TLRanges = artifacts.require("./TLRanges.sol"); 
var TiesDB = artifacts.require("./TiesDB.sol");

module.exports = function(deployer) {
  deployer.deploy(TLRanges);
  deployer.link(TLRanges, TLNode);

  deployer.deploy(TLNode);
  deployer.link(TLNode, TLStorage);

  deployer.deploy(TLStorage);
  deployer.deploy(TLTable);
  deployer.deploy(TLTblspace);
  
  deployer.link(TLNode, TiesDB);
  deployer.link(TLStorage, TiesDB);
  deployer.link(TLTable, TiesDB);
  deployer.link(TLTblspace, TiesDB);

  deployer.deploy(TiesDB);
};
