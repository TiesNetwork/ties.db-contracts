pragma solidity ^0.4.11;


import 'zeppelin/contracts/token/BasicToken.sol';
import './ERC23.sol';
import './ERC23PayableReceiver.sol';

/**  https://github.com/Dexaran/ERC23-tokens/blob/master/token/ERC223/ERC223BasicToken.sol
 *
 */
contract ERC23PayableToken is BasicToken, ERC23{
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address to, uint value, bytes data) {
        transferAndPay(to, value, data);
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address to, uint value) {
        bytes memory empty;
        transfer(to, value, empty);
    }

    function transferAndPay(address to, uint value, bytes data) payable{
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(to)
        }

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        if(codeLength>0) {
            ERC23PayableReceiver receiver = ERC23PayableReceiver(to);
            receiver.tokenFallback.value(msg.value)(msg.sender, value, data);
        }else if(msg.value > 0){
            assert(to.send(msg.value));
        }

        Transfer(msg.sender, to, value);
        if(data.length > 0)
            TransferData(msg.sender, to, value, data);
    }
}