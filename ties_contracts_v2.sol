pragma solidity ^0.4.15;

library TiesLibString {

    bytes32 private constant emptyHash = 0x0;

    function hash(string s) internal constant returns (bytes32) {
        return sha3(s);
    }

    using TiesLibString for string;

    function equals(string s, string x) internal constant returns (bool) {
        return s.hash() == x.hash();
    }

    function isEmpty(string s) internal constant returns (bool) {
        return s.hash() == emptyHash;
    }
}

library TiesLibAddress {
    
    address private constant freeAddress = address(0);

    function isFree(address s) internal constant returns (bool) {
        return s == freeAddress;
    }
}

interface TiesDBRestrictions {
    function canCreateTablespace(string tsName, address owner) public constant returns (bool);
    function canDeleteTablespace(string tsName, address owner) public constant returns (bool);
    function canCreateTable(string tsName, address owner) public constant returns (bool);
}

contract TiesDBRestrictionsOwner {

    using TiesLibString for string;
    using TiesLibAddress for address;

    mapping(bytes32 => address) public ts;

    function registerOwner(string tsName) public {
        require(ts[tsName.hash()].isFree());
        ts[tsName.hash()] = msg.sender;
    }
    function canCreateTablespace(string tsName, address owner) public constant returns (bool) {
        return ts[tsName.hash()] == owner;
    }
    function canDeleteTablespace(string tsName, address owner) public constant returns (bool) {
        return ts[tsName.hash()] == owner;
    }
    function canCreateTable(string tsName, address owner) public constant returns (bool) {
        return ts[tsName.hash()] == owner;
    }
}

contract TiesDB {

    using TiesLibString for string;
    using TiesLibAddress for address;

    mapping(bytes32 => Tablespace) public ts;

    struct Tablespace {
        TiesDBRestrictions rs;
        mapping(bytes32 => Table) t;
        string[] tn;
    }

    struct Table {
        Tablespace ts;
        mapping(bytes32 => Field) t;
    }

    struct Field {
    }

    function createTablespace(string tsName, TiesDBRestrictions rs) public {
        require(!hasTablespace(tsName) && rs.canCreateTablespace(tsName, msg.sender));
        ts[tsName.hash()] = Tablespace({rs: rs, tn: new string[](0)});
    }

    function deleteTablespace(string tsName) public {
        require(hasTablespace(tsName) && ts[tsName.hash()].rs.canDeleteTablespace(tsName, msg.sender));
        delete ts[tsName.hash()];
    }

    function hasTablespace(string tsName) constant public returns (bool) {
        return !address(ts[tsName.hash()].rs).isFree();
    }

    // function getTableNames(string tsName) constant returns (string) {
    //     return ts[sha3(tsName)].tn;
    // }

    function hasTable(string tsName, string tName) constant public returns (bool) {
        return address(ts[tsName.hash()].t[tName.hash()].ts.rs).isFree();
    }
}











