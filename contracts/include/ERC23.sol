pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";


/*
 * ERC23
 * ERC23 interface
 * see https://github.com/ethereum/EIPs/issues/223
 */
contract ERC23 is ERC20 {
    function transferData(address to, uint value, bytes memory data) public;

    event TransferData(address indexed from, address indexed to, uint value, bytes data);
}
