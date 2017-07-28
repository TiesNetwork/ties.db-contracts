# Ties.Network Contracts

## Dependencies
We use Truffle in order to compile and test the contracts.

It can be installed:
`npm install -g truffle`

For more information visit https://truffle.readthedocs.io/en/latest/

We also depend on Zeppelin libraries. Install it with
`truffle install zeppelin`

Also running node with active json-rpc is required. For testing puproses we suggest using https://github.com/ethereumjs/testrpc
## Usage
`./run_testrpc.bat` - run testrpc node with required params

`truffle compile` - compile all contracts

`truffle test` - run tests
