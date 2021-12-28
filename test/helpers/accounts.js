const logger = require('./logger');

const secrets = [
    "0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3", //accounts[0]
    "0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f", //accounts[1]
    "0x0dbbe8e4ae425a6d2687f1a7e3ba17bc98c673636790f1b8ad91193c05875ef1", //accounts[2]
    "0xc88b703fb08cbea894b6aeff5a544fb92e78a18e19814cd85da83b71f772aa6c", //accounts[3]
    "0xef4343e2d897a4636db8ed2f92acce614264950aa507b7e049e1668681339d18", //accounts[4]
    "0x907bff6e017e380ac25e49ad86277c998d0b8d9c9ddf24362e5a3885bfa40ab1", //accounts[5]
    "0x930cb70c51725ee9511e13140f3461db666b7923e6ba0c5497668d5e7477bf50", //accounts[6]
];

async function fixBalance(baseAccount, account, targetBalance) {
    let balance = await web3.eth.getBalance(account).then(web3.utils.toBN);
    logger.debug("balance " + account + " : " + balance);
    if(balance.lt(targetBalance)) {
        let amount = targetBalance.sub(balance);
        logger.debug("transfer " + account + " from " + baseAccount + ": " + amount);
        await web3.eth.sendTransaction({ from: baseAccount, to: account, value: amount });
    }
}

async function initAccounts(baseAccount, count) {
    assert.ok(secrets.length >= count, "Not enough secrets for " + count + " accounts");
    let accounts = [count];
    let actions = []
    let amount = toWei(1, 'ether');
    for (let i = 0; i < count; i++) {
        actions.push((async function(){
            let privateKey = secrets[i];
            let account = web3.eth.accounts.privateKeyToAccount(privateKey).address;
            try {
                await web3.eth.personal.unlockAccount(account, '1', 12600);
                logger.debug("unlocked " + account);
                await fixBalance(baseAccount, account, amount);
                accounts[i] = account;
            } catch (unlockingError) {
                logger.trace(unlockingError);
                logger.debug("creating " + account);
                let createdAccount;
                try {
                    createdAccount = await web3.eth.personal.importRawKey(privateKey, '1');
                } catch (creationError) {
                    if(privateKey.substr(0, 2) === "0x") {
                        let trimmedPrivateKey = privateKey.substr(2);
                        try {
                            createdAccount = await web3.eth.personal.importRawKey(trimmedPrivateKey, '1');
                        } catch (recreationError) {
                            logger.error(unlockingError);
                            assert.fail(recreationError);
                        }
                    } else {
                        logger.error(unlockingError);
                        assert.fail(creationError);
                    }
                }
                assert.ok(account.toUpperCase() === createdAccount.toUpperCase(), "Account " + account + " creation failed");
                await web3.eth.personal.unlockAccount(account, '1', 12600);
                await fixBalance(baseAccount, account, amount);
                accounts[i] = account;
            }
        })());
    }
    await Promise.all(actions);
    accounts.forEach((account, i) => {
        if(undefined === account) {
            assert.fail("Account " + i + " was not unlocked");
        }
        logger.log("account " + i + ": " + account);
    });
    return accounts;
}

function toWei(amount, unit) {
    return web3.utils.toWei(web3.utils.toBN(amount), unit);
}

function getSecret(index) {
    assert.ok(index < secrets.length, "Secret index out of range: " + index + " of " + secrets.length);
    return secrets[index];
}

module.exports = {
    getAccounts: initAccounts,
    getSecret: getSecret,
}