pragma solidity ^0.4.11;


import "./include/MintableToken.sol";
import "./include/ERC23PayableToken.sol";


/*
 * Tie Token
 *
 * The TieToken is mintable during ICO. On ICO finalization it
 * will be minted up to the cap and minting will be finished forever
 */
contract TieToken is MintableToken, ERC23PayableToken {
    string public constant name = "TieToken";
    string public constant symbol = "TIE";
    uint public constant decimals = 18;

    //The cap is 200 mln TIEs
    uint private constant CAP = 200*(10**6)*(10**decimals);

    function mint(address _to, uint _amount){
        require(totalSupply.add(_amount) <= CAP);
        super.mint(_to, _amount);
    }

    function TieToken(address multisigOwner) {
        //Transfer ownership on the token to multisig on creation
        transferOwnership(multisigOwner);
    }


}
