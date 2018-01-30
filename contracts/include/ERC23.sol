pragma solidity ^0.4.11;

import "localhost/zeppelin/contracts/token/ERC20Basic.sol";


/*
 * ERC23
 * ERC23 interface
 * see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC23 is ERC20Basic {
    function transfer(address to, uint value, bytes data) public;

    event TransferData(address indexed from, address indexed to, uint value, bytes data);
}
