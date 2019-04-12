let logLevel = process.env.TRUFFLE_TEST_LOG_LEVEL || 0;

function register(level, command) {
    if(logLevel < level) {
        return function(){};
    }
    return command;
}

module.exports = {
    error: register(0, console.error),
    info: register(1, console.info),
    log: register(2, console.log),
    debug: register(3, console.debug),
    trace: register(4, console.trace),
}
