module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  networks: {
    devlocal: {
      host: "localhost",
      port: 18545,
      network_id: 1337, // Match geth development network id
    }
  }
};
