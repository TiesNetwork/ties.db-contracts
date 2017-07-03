pragma solidity ^0.4.11;


import "zeppelin/contracts/token/MintableToken.sol";


/*
 * Tie Token
 *
 * This is non production token implementation!!!
 * During RnD stage we make it mintable for convenience
 */
contract TieToken is MintableToken {
    string public constant name = "TieToken";
    string public constant symbol = "TIE";
    uint public constant decimals = 18;
}
