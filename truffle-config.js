module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    rinkeby: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 4, // Match any network id
      from: '0x97E8a07c9e1FB432f8fD9066eEc2c7170aF734EE',
      gasPrice: 100000000,
    }
  }
};
