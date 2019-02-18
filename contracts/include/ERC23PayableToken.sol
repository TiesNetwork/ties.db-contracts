pragma solidity ^0.5.0;


import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./ERC23.sol";
import "./ERC23PayableReceiver.sol";


/**  https://github.com/Dexaran/ERC23-tokens/blob/master/token/ERC223/ERC223BasicToken.sol
 *
 */
contract ERC23PayableToken is ERC20, ERC23 {
    // Function that is called when a user or another contract wants to transfer funds .
    function transferData(address to, uint value, bytes memory data) public {
        transferAndPay(to, value, data);
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address to, uint value) public returns (bool) {
        bytes memory empty;
        transferData(to, value, empty);
        return true;
    }

    function transferAndPay(address to, uint value, bytes memory data) public payable {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(to)
        }

        super.transfer(to, value);

        if (codeLength > 0) {
            ERC23PayableReceiver receiver = ERC23PayableReceiver(to);
            receiver.tokenFallback.value(msg.value)(msg.sender, value, data);
        } else if (msg.value > 0) {
            transfer(to, msg.value);
        }

        if (data.length > 0)
            emit TransferData(msg.sender, to, value, data);
    }
}