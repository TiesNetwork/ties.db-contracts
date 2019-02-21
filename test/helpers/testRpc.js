// timer for tests specific to testrpc
function assertJump(error) {
//	console.log(error.message);
  	assert.isOk(/revert|invalid opcode/.test(error.message), 'Transaction should revert');
}

module.exports = {
	increaseTime: function(s) {
      return new Promise((resolve, reject) => {
        web3.currentProvider.sendAsync({
          jsonrpc: '2.0', 
          method: 'evm_increaseTime',
          params: [s], // 60 seaconds, may need to be hex, I forget
          id: new Date().getTime() // Id of the request; anything works, really
        }, function(err) {
          if (err) return reject(err);
          resolve();
        });
      })},
	snapshot: function() {
      return new Promise((resolve, reject) => {
        web3.currentProvider.sendAsync({
          jsonrpc: '2.0', 
          method: 'evm_snapshot',
          params: [], 
          id: new Date().getTime() // Id of the request; anything works, really
        }, function(err, result) {
          if (err) return reject(err);
          resolve(result);
        });
      })},
	revert: function(s) {
      return new Promise((resolve, reject) => {
        web3.currentProvider.sendAsync({
          jsonrpc: '2.0', 
          method: 'evm_revert',
          params: [s], //Snapshot id
          id: new Date().getTime() // Id of the request; anything works, really
        }, function(err, result) {
          if (err) return reject(err);
          resolve(result);
        });
      })},
    mine: function() {
      return new Promise((resolve, reject) => {
        web3.currentProvider.sendAsync({
          jsonrpc: '2.0', 
          method: 'evm_mine',
          params: [], //Snapshot id
          id: new Date().getTime() // Id of the request; anything works, really
        }, function(err) {
          if (err) return reject(err);
          resolve();
        });
      })},
    assertJump: assertJump,
	assertThrow: async function(msg, cb){
        let thrown;
        try {
            thrown = false;
        	await cb();
        } catch(error) {
            thrown = true;
            assertJump(error);
        }
        assert.isOk(thrown, msg);
	}
};
