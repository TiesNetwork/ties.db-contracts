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


pragma solidity ^0.5.0;


import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./include/ERC23PayableToken.sol";


contract TieToken is ERC20Mintable, Ownable, ERC23PayableToken {
    string public constant name = "TieToken";
    string public constant symbol = "TIE";
    uint public constant decimals = 18;

    bool public transferEnabled = false;

    //The cap is 200 mln TIEs
    uint private constant CAP = 200*(10**6)*(10**decimals);

    constructor(address multisigOwner) public {
        //Transfer ownership on the token to multisig on creation
        if(multisigOwner != msg.sender) {
            setMinter(multisigOwner);
            transferOwnership(multisigOwner);
        }
    }

    function addMinter(address account) public onlyOwner {
        super.addMinter(account);
    }

    function setMinter(address _minter) public onlyOwner {
        require(_minter != owner(), "Already minter");
        addMinter(_minter);
        renounceMinter();
    }

    function mint(address _to, uint _amount) public returns (bool) {
        require((totalSupply() + _amount) <= CAP, "Cap is exceeded");
        super.mint(_to, _amount);
    }

    /**
    * Overriding all transfers to check if transfers are enabled
    */
    function transferAndPay(address to, uint value, bytes memory data) public payable {
        require(transferEnabled, "Transfer should be enabled (tap)");
        super.transferAndPay(to, value, data);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transferEnabled, "Transfer should be enabled");
        if(_from == msg.sender) {
            return super.transfer(_to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    function enableTransfer(bool enabled) public onlyOwner {
        transferEnabled = enabled;
    }

}
