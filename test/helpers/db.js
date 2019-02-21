function getHash(name){
    let hash = web3.utils.keccak256(name);
    return hash;
}

function getTableHash(tblspc, tbl){
    return getHash(tblspc + '#' + tbl);
}

module.exports = {
    getHash: getHash,
    getTableHash: getTableHash
}