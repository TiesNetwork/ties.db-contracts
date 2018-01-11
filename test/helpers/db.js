function getHash(name){
    let hash = web3.sha3(name);
    let bn = web3.toAscii(hash);
    return bn;
}

function getTableHash(tblspc, tbl){
    return getHash(tblspc + '#' + tbl);
}

module.exports = {
    getHash: getHash,
    getTableHash: getTableHash
}