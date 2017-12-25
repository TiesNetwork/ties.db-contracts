var TLStorage = artifacts.require("./TLStorage.sol");
var TLTable = artifacts.require("./TLTable.sol"); 
var TLTblspace = artifacts.require("./TLTblspace.sol");
var TiesDB = artifacts.require("./TiesDB.sol");

module.exports = function(deployer) {
  deployer.deploy(TLStorage);
  deployer.deploy(TLTable);
  deployer.deploy(TLTblspace);
  
  deployer.link(TLStorage, TiesDB);
  deployer.link(TLTable, TiesDB);
  deployer.link(TLTblspace, TiesDB);

  deployer.deploy(TiesDB);
};
