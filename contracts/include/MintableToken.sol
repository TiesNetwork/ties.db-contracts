pragma solidity ^0.4.11;

import 'zeppelin/contracts/token/StandardToken.sol';
import 'zeppelin/contracts/ownership/Ownable.sol';

/**
 * Mintable token
 *
 * Simple ERC20 Token example, with mintable token creation
 * Based on zeppelin/contracts/token/MintableToken.sol but code is simplified
 * and Mint event is replaced to Transfer to show minted tokens on Etherscan
 */

contract MintableToken is StandardToken, Ownable {
    event MintFinished();

    bool public mintingFinished = false;
    uint public totalSupply = 0;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address _to, uint _amount) onlyOwner canMint {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0x0), _to, _amount);
    }

    function finishMinting() onlyOwner {
        mintingFinished = true;
        MintFinished();
    }
}
