/*
 * Tie Token smart contract
 *
 * Supports ERC20, ERC223 stadards
 *
 * The TieToken is mintable during Token Sale. On Token Sale finalization it
 * will be minted up to the cap and minting will be finished forever
 *
 * @author Dmitry Kochin <k@ties.network>
 */


pragma solidity ^0.4.18;


import "./include/MintableToken.sol";
import "./include/ERC23PayableToken.sol";


contract TieToken is MintableToken, ERC23PayableToken {
    string public constant name = "TieToken";
    string public constant symbol = "TIE";
    uint public constant decimals = 18;

    bool public transferEnabled = false;

    //The cap is 200 mln TIEs
    uint private constant CAP = 200*(10**6)*(10**decimals);

    function TieToken(address multisigOwner) {
        //Transfer ownership on the token to multisig on creation
        transferOwnership(multisigOwner);
    }

    function mint(address _to, uint _amount) {
        require(totalSupply.add(_amount) <= CAP);
        super.mint(_to, _amount);
    }

    /**
    * Overriding all transfers to check if transfers are enabled
    */
    function transferAndPay(address to, uint value, bytes data) payable {
        require(transferEnabled);
        super.transferAndPay(to, value, data);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transferEnabled);
        return super.transferFrom(_from, _to, _value);
    }

    function enableTransfer(bool enabled) public onlyOwner {
        transferEnabled = enabled;
    }

}
