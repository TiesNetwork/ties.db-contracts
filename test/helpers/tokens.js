const decimals = 18;

const zeroes = web3.utils.toBN(10).pow(web3.utils.toBN(decimals));

function asTokens(value) {
    return web3.utils.toBN(value).mul(zeroes);
};

module.exports = {
    asTokens: asTokens,
}