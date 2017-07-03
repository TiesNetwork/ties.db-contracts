pragma solidity ^0.4.11;


import "zeppelin/contracts/token/ERC20.sol";


// This contract manages all user deposits for TiesDB

contract UserRegistry {
	/**
     * TIE tokens deposits
     */

    struct User {
        uint deposit;
        mapping (address => uint) sent;
    }

    /// @notice Overdraft event
    event Overdraft(address deadbeat);
    event ChequeRedeemed(address issuer, address beneficiary, uint total, uint claimed, uint redeemed);
    event Error(string text);

	mapping (address => User) public users;
    ERC20 token;

    function UserRegistry(address _token){
        token = ERC20(_token);
    }

    function addDeposit(uint amount) public {
        //If there is no allowance or not enough tokens it will throw
        users[msg.sender].deposit += amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    /// Gets the deposit of the specified user
    function getDeposit(address user) public constant returns (uint){
        return users[user].deposit;
    }

    /// Gets the amount sent to the beneficiary by the specified user
    function getSent(address user, address beneficiary) public constant returns (uint){
        return users[user].sent[beneficiary];
    }

    /**
     * We will not throw in this function to not burn extra gas if the cheque is invalid
     */
    function cashCheque(address issuer, address beneficiary, uint amount, uint8 sig_v, bytes32 sig_r, bytes32 sig_s) returns (uint){
        User u = users[issuer];
        uint sent = u.sent[beneficiary];

        // Check if the cheque is old.
        // Only cheques that are more recent than the last cashed one are considered.
        if(amount <= sent){
            Error("Cheque was already redeemed");
            return 0;
        }

        // Check the digital signature of the cheque.
        bytes32 hash = sha3(issuer, beneficiary, amount);
        if(issuer != ecrecover(hash, sig_v, sig_r, sig_s)){
            Error("Signature check failed");
            return 0;
        }

        uint tosend = amount - sent;

        if(tosend > u.deposit) {
            //user does not have enough on their deposit
            //We send everything to cash the cheque. The check can be used later
            //once more to cash the rest if the user tops up the deposit
            tosend = u.deposit;
            u.sent[beneficiary] += tosend;
            u.deposit = 0;
            token.transfer(beneficiary, tosend);

            Overdraft(issuer);
        }else{
            //User has enough tokens to pay the cheque
            u.sent[beneficiary] = amount;
            u.deposit -= tosend;
            token.transfer(beneficiary, tosend);
        }

        ChequeRedeemed(issuer, beneficiary, amount, amount-sent, tosend);

        return tosend;
    }

}
