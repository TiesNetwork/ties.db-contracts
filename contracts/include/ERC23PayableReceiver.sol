pragma solidity ^0.4.11;

/*
* Contract that is working with ERC223 tokens
*/

contract ERC23PayableReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) payable;
}