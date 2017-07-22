pragma solidity ^0.4.0;


import "./include/ERC23PayableReceiver.sol";
import "./TieToken.sol";


/**
*  Invitation contract is used to issue and redeem invitation codes
*/
contract Invitation is ERC23PayableReceiver{
    TieToken token;

    struct Info{
        uint128 tokens;
        uint128 value;
    }

    struct Invites {
        uint total;
        mapping(uint => Info) infos;
    }

    mapping(address => Invites) invites;

    event InviteNew(address indexed who, uint index, uint128 tokens, uint128 value);
    event Invited(address indexed _from, address indexed _to, uint index, uint128 tokens, uint128 value);
    event InviteDeleted(address indexed _from, uint index, uint128 tokens, uint128 value);

    event Error(string message);
    event Error1(string message, uint val);

    function Invitation(address _token){
        token = TieToken(_token);
    }

    //To make an invitation just send ether and tokens with TieToken.transfer() to this contract
    function tokenFallback(address _from, uint _value, bytes _data) payable {
        require(msg.sender == address(token));

//        Error1("min val", 10*(10**token.decimals()));
        //We accept minimum 10 TIE and 0.1 ether as an invitation deposit
        require(_value >= 10*(10**token.decimals()));
        require(msg.value >= 0.1 ether);
        require(_value < 2**128 && msg.value < 2**128);

        Invites inv = invites[_from];
        inv.infos[++inv.total] = Info(uint128(_value), uint128(msg.value));

        InviteNew(_from, inv.total, inv.infos[inv.total].tokens, inv.infos[inv.total].value);
    }

    function getLastInvite(address _from) constant returns (uint){
        return invites[_from].total;
    }

    function isInvitationAvailable(address _from, uint _invite) constant returns (bool){
        return invites[_from].infos[_invite].tokens > 0;
    }

    /**
     * We will not throw in this function to not burn extra gas if the invitation is invalid
     */
    function redeem(address _to, address _from, uint index, uint8 sig_v, bytes32 sig_r, bytes32 sig_s) returns (bool){
        Invites inv = invites[_from];
        Info inf = inv.infos[index];
        uint128 tokens = inf.tokens;
        uint128 val = inf.value;

        // Check if the cheque is old.
        // Only cheques that are more recent than the last cashed one are considered.
        if(tokens == 0){
            Error("Invitation is no longer available");
            return false;
        }

        // Check the digital signature of the cheque.
        bytes32 hash = sha3("TIE invitation", index);
        if(_from != ecrecover(hash, sig_v, sig_r, sig_s)){
            Error("Invitation signature check failed");
            return false;
        }

        delete inv.infos[index];

        bytes memory empty;
        token.transferAndPay.value(val)(_to, tokens, empty);

        if(_to != _from)
            Invited(_from, _to, index, tokens, val);
        else
            InviteDeleted(_from, index, tokens, val);

        return true;
    }


}
