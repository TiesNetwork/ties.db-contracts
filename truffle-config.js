module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: 1337
    },
    devlocal: {
      host: "127.0.0.1",
      port: 18545,
      network_id: 1337, // Match geth development network id
    }
  }
};
