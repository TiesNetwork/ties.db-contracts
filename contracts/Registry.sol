pragma solidity ^0.5.0;


import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./include/ERC23PayableReceiver.sol";
import "./structure/TiesDBAPI.sol";

// This contract manages all user deposits for TiesDB

contract Registry is ERC23PayableReceiver, TiesDBPayment {
    using SafeMath for uint;
    /**
     * TIE tokens deposits
     */

    struct Redeem {
        uint sent;
        uint64 lastTimeStamp; //The timestamp of the last redeemed cheque
    }
    struct User {
        uint deposit;
        mapping (address => Redeem) sent;
    }

    struct Node {
        uint deposit;
    }

    /// @notice Overdraft event
    event Overdraft(address deadbeat);
    event ChequeRedeemed(address issuer, address beneficiary, uint total, uint claimed, uint redeemed);
    event Error(string text);

    mapping (address => User) public users;
    mapping (address => Node) public nodes;
    ERC20 public token;
    TiesDBNodes public tiesDB;

    constructor(address _token, address _tiesDB) public {
        token = ERC20(_token);
        tiesDB = TiesDBNodes(_tiesDB);
    }

    function payFrom(address payer, address payee, uint amount) public returns (bool) {
        require(msg.sender == address(tiesDB), "Payment authentication failure");
        User storage user = users[payer];
        require(amount <= user.deposit, "Insufficient user deposit");
        Node storage node = nodes[payee];
        require(node.deposit > 0, "Node deposit should be positive");
        user.deposit -= amount;
        return token.transfer(payee, amount);
    }

    function addUserDeposit(uint amount) public {
        //If there is no allowance or not enough tokens it will throw
        users[msg.sender].deposit = users[msg.sender].deposit.add(amount);
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failure adding user deposit");
    }

    function addNodeDeposit(uint amount) public {
        //If there is no allowance or not enough tokens it will throw
        _addNodeDeposit(msg.sender, amount);
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failure adding node deposit");
    }

    /// Gets the deposit of the specified user
    function getUserDeposit(address user) public view returns (uint) {
        return users[user].deposit;
    }

    /// Gets the deposit of the specified node
    function getNodeDeposit(address node) public view returns (uint) {
        return nodes[node].deposit;
    }

    /// Gets the amount sent to the beneficiary by the specified user
    function getSent(address user, address beneficiary) public view returns (uint) {
        return users[user].sent[beneficiary].sent;
    }

    function wtf(string memory message) internal returns (bool){
        return wtf(true, message);
    }

    function wtf(bool condition, string memory message) internal returns (bool){
        require(!condition, message);
        // If require was not fired
        if(condition) {
            emit Error(message);
        }
        return condition;
    }

    function tokenFallback(address _from, uint _value, bytes memory _data) public payable {
        if(wtf(msg.sender != address(token), "Wrong token")) return;
        if(wtf(msg.value != 0, "Registry does not accept ether")) //Do not accept ether
            return;
        
        if (_data.length >= 4) {
            uint32 val = (((((uint8(_data[0]) << 8) + uint8(_data[1])) << 8) + uint8(_data[2])) << 8) + uint8(_data[3]);

            if (val == 0) {
                _addUserDeposit(_from, _value);
            } else if (val == 1) {
                _addNodeDeposit(_from, _value);
            } else {
                wtf("Wrong data"); //Currently can only accept data with 0x 00 00 00 xx
            }
        } else {

            if(wtf(_data.length > 0, "Non empty data")) //Data should not be here!
                return;
            
            _addUserDeposit(_from, _value);
        }
        // wtf("Was in tokenFallback");
    }

    /**
     * We will not throw in this function to not burn extra gas if the cheque is invalid
     * Transfer of checks is only possible from users to nodes
     */
    function cashCheque(address issuer, address beneficiary, uint amount, uint64 lastTimeStamp,
        uint8 sigv, bytes32 sigr, bytes32 sigs) public returns (uint) {

        Node storage node = nodes[beneficiary];
        require(node.deposit > 0, "Node deposit should be positive");

        User storage u = users[issuer];
        Redeem storage r = u.sent[beneficiary];

        // Check if the cheque is old.
        // Only cheques that are more recent than the last cashed one are considered.
        if (amount <= r.sent || lastTimeStamp < r.lastTimeStamp ) {
            emit Error("Cheque was already redeemed");
            return 0; //revert();
        }

        // Check the digital signature of the cheque.
        bytes32 hash = keccak256(abi.encodePacked("TIE cheque", issuer, beneficiary, amount, lastTimeStamp));
        if (issuer != ecrecover(hash, sigv, sigr, sigs)) {
            emit Error("Signature check failed");
            return 0; //revert();
        }

        uint tosend = amount - r.sent;
        r.lastTimeStamp = lastTimeStamp;

        if (tosend > u.deposit) {
            //user does not have enough on their deposit
            //We send everything to cash the cheque. The check can be used later
            //once more to cash the rest if the user tops up the deposit
            tosend = u.deposit;
            r.sent += tosend;
            u.deposit = 0;
            token.transfer(beneficiary, tosend);

            emit Overdraft(issuer);
        } else {
            //User has enough tokens to pay the cheque
            r.sent = amount;
            u.deposit -= tosend;
            token.transfer(beneficiary, tosend);
        }

        emit ChequeRedeemed(issuer, beneficiary, amount, amount-r.sent, tosend);

        return tosend;
    }

    function _addUserDeposit(address from, uint amount) internal {
        require(amount > 0, "User topup amount should be positive");
        users[from].deposit = users[from].deposit.add(amount);
    }

    function _addNodeDeposit(address from, uint amount) internal {
        require(amount > 0, "Node topup amount should be positive");
        nodes[from].deposit = nodes[from].deposit.add(amount);
        tiesDB.createNode(from);
    }

    function acceptRanges(bool accept) public {
        address from = msg.sender;
        require(nodes[from].deposit > 0, "Node has zero deposit");

        if (accept) {
            tiesDB.queueNode(from);
        } else {
            tiesDB.unqueueNode(from);
        }
    }

}
