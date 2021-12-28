const Migrations = artifacts.require("./Migrations.sol");

module.exports = function(deployer) {
  if(process.env.TRUFFLE_SKIP_MIGRATIONS === 'Y') {
    return;
  }
  deployer.deploy(Migrations);
};
