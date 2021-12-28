pragma solidity ^0.5.0;

/*
* Contract that is working with ERC223 tokens
*/

contract ERC23PayableReceiver {
    function tokenFallback(address _from, uint _value, bytes memory _data) public payable;
}