pragma solidity ^0.4.18;

import "..//structure/TiesDBAPI.sol";

contract NoRestrictions is TiesDBRestrictions {
    function canCreateTablespace(string, address) public constant returns (bool) { return true; }
    function canDeleteTablespace(string, address) public constant returns (bool) { return true; }

    function canCreateTable(string, string, address) public constant returns (bool) { return true; }
    function canDeleteTable(string, string, address) public constant returns (bool) { return true; }
    function canDistributeRanges(string, string, address) public constant returns (bool) { return true; }

    function canCreateField(string, string, string, address) public constant returns (bool) { return true; }
    function canDeleteField(string, string, string, address) public constant returns (bool) { return true; }

    function canCreateTrigger(string, string, string, address) public constant returns (bool) { return true; }
    function canDeleteTrigger(string, string, string, address) public constant returns (bool) { return true; }

    function canCreateIndex(string, string, string, address) public constant returns (bool) {
        return true;
    }

    function canDeleteIndex(string, string, string, address) public constant returns (bool) {
        return true;
    }
}
