pragma solidity ^0.4.11;

library TiesLibString {

    bytes32 private constant emptyHash = sha3();

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
    function canCreateTablespace(bytes32 tsKey, address owner) public constant returns (bool);
    function canDeleteTablespace(bytes32 tsKey, address owner) public constant returns (bool);
    function canCreateTable(bytes32 tsKey, bytes32 tKey, address owner) public constant returns (bool);
    function canDeleteTable(bytes32 tsKey, bytes32 tKey, address owner) public constant returns (bool);
    function canCreateField(bytes32 tsKey, bytes32 tKey, bytes32 fKey, address owner) public constant returns (bool);
    function canDeleteField(bytes32 tsKey, bytes32 tKey, bytes32 fKey, address owner) public constant returns (bool);
}

contract TiesDBRestrictionsOwner {

    using TiesLibString for string;
    using TiesLibAddress for address;

    mapping(bytes32 => address) private tsm;

    function registerOwner(bytes32 tsKey, address owner) public {
        require(tsKey != 0);
        require(tsm[tsKey].isFree());
        tsm[tsKey] = owner;
    }

    function canCreateTablespace(bytes32 tsKey, address owner) public constant returns (bool) {
        require(tsKey != 0);
        return tsm[tsKey] == owner;
    }

    function canDeleteTablespace(bytes32 tsKey, address owner) public constant returns (bool) {
        require(tsKey != 0);
        return tsm[tsKey] == owner;
    }

    function canCreateTable(bytes32 tsKey, bytes32 tKey, address owner) public constant returns (bool) {
        require(tsKey != 0 && tKey != 0);
        return tsm[tsKey] == owner;
    }

    function canDeleteTable(bytes32 tsKey, bytes32 tKey, address owner) public constant returns (bool) {
        require(tsKey != 0 && tKey != 0);
        return tsm[tsKey] == owner;
    }

    function canCreateField(bytes32 tsKey, bytes32 tKey, bytes32 fKey, address owner) public constant returns (bool) {
        require(tsKey != 0 && tKey != 0 && fKey != 0);
        return tsm[tsKey] == owner;
    }
    function canDeleteField(bytes32 tsKey, bytes32 tKey, bytes32 fKey, address owner) public constant returns (bool) {
        require(tsKey != 0 && tKey != 0 && fKey != 0);
        return tsm[tsKey] == owner;
    }
}

contract TiesDBCore {
    
    using TiesLibAddress for address;
    using TiesLibString for string;

    mapping(bytes32 => Tablespace) internal tsm;
    bytes32[] tsmis;
    
    struct Tablespace {
        TiesDBRestrictions rs;
        string name;
        uint256 tsmi;
        mapping(bytes32 => Table) tm;
        bytes32[] tmis;
    }

    struct Table {
        Tablespace ts;
        string name;
        uint256 tmi;
        mapping(bytes32 => Field) fm;
        bytes32[] fmis;
    }

    struct Field {
        Table t;
        string name;
        uint256 fmi;
    }

    function _isSet(Tablespace ts) constant internal returns (bool) {
        return !address(ts.rs).isFree();
    }

    function _isSet(Table t) constant internal returns (bool) {
        return !address(t.ts.rs).isFree();
    }

    function _isSet(Field f) constant internal returns (bool) {
        return !address(f.t.ts.rs).isFree();
    }

    function getTablespaceKeys() constant public returns (bytes32[]) {
        return tsmis;
    }

    function _deleteTable(Tablespace storage ts, bytes32 tKey) internal {
        if(ts.tmis.length > 1){
            ts.tmis[ts.tm[tKey].tmi] = ts.tmis[ts.tmis.length-1];
        }
        ts.tmis.length--;
        delete ts.tm[tKey];
    }

    function _deleteField(Table storage t, bytes32 fKey) internal {
        if(t.fmis.length > 1){
            t.fmis[t.fm[fKey].fmi] = t.fmis[t.fmis.length-1];
        }
        t.fmis.length--;
        delete t.fm[fKey];
    }

    function getVersion() constant public returns (string);
}

contract TiesDBTablespace is TiesDBCore {

    function createTablespace(string tsName, TiesDBRestrictions rs) public returns (bytes32) {
        var tsKey = tsName.hash();
        require(!_isSet(tsm[tsKey]) && rs.canCreateTablespace(tsKey, msg.sender));
        tsm[tsName.hash()] = Tablespace({name: tsName, rs: rs, tsmi: tsmis.length, tmis: new bytes32[](0)});
        tsmis.push(tsKey);
        return tsKey;
    }

    function deleteTablespace(bytes32 tsKey) public {
        var ts = tsm[tsKey];
        require(_isSet(ts) && ts.rs.canDeleteTablespace(tsKey, msg.sender));
        if(tsmis.length > 1){
            tsmis[ts.tsmi] = tsmis[tsmis.length-1];
        }
        tsmis.length--;
    }

    function hasTablespace(bytes32 tsKey) constant public returns (bool) {
        return _isSet(tsm[tsKey]);
    }
    
    function getTablespaceName(bytes32 tsKey) constant public returns (string) {
        var ts = tsm[tsKey];
        require(_isSet(ts));
        return ts.name;
    }

    function getTablespaceTablesKeys(bytes32 tsKey) constant public returns (bytes32[]) {
        var ts = tsm[tsKey];
        require(_isSet(ts));
        return ts.tmis;
    }
}

contract TiesDBTable is TiesDBCore {

    using TiesLibString for string;

    function createTable(bytes32 tsKey, string tName) public returns (bytes32) {
        var tKey = tName.hash();
        var ts = tsm[tsKey];
        require(!hasTable(tsKey, tKey) && ts.rs.canCreateTable(tsKey, tKey, msg.sender));
        ts.tm[tKey] = Table({name: tName, ts: ts, tmi: ts.tmis.length, fmis: new bytes32[](0)});
        ts.tmis.push(tKey);
        return tKey;
    }

    function deleteTable(bytes32 tsKey, bytes32 tKey) public {
        var ts = tsm[tsKey];
        var t = ts.tm[tKey];
        require(_isSet(t) && ts.rs.canDeleteTable(tsKey, tKey, msg.sender));
        if(ts.tmis.length > 1){
            ts.tmis[t.tmi] = ts.tmis[ts.tmis.length-1];
        }
        ts.tmis.length--;
    }

    function hasTable(bytes32 tsKey, bytes32 tKey) constant public returns (bool) {
        return _isSet(tsm[tsKey].tm[tKey]);
    }
    
    function getTableName(bytes32 tsKey, bytes32 tKey) constant public returns (string) {
        var t = tsm[tsKey].tm[tKey];
        require(_isSet(t));
        return t.name;
    }

    function getTableFieldsKeys(bytes32 tsKey, bytes32 tKey) constant public returns (bytes32[]) {
        var t = tsm[tsKey].tm[tKey];
        require(_isSet(t));
        return t.fmis;
    }
}

contract TiesDBField is TiesDBCore {

    using TiesLibString for string;

    function createField(bytes32 tsKey, bytes32 tKey, string fName) public returns (bytes32) {
        var fKey = fName.hash();
        var t = tsm[tsKey].tm[tKey];
        require(_isSet(t) && !_isSet(t.fm[fKey]) && t.ts.rs.canCreateField(tsKey, tKey, fKey, msg.sender));
        t.fm[fKey] = Field({name: fName, t: t, fmi: t.fmis.length});
        t.fmis.push(fKey);
        return fKey;
    }

    function deleteField(bytes32 tsKey, bytes32 tKey, bytes32 fKey) public returns (bytes32) {
        var t = tsm[tsKey].tm[tKey];
        var f = t.fm[fKey];
        require(_isSet(f) && t.ts.rs.canDeleteField(tsKey, tKey, fKey, msg.sender));
        if(t.fmis.length > 1){
            t.fmis[f.fmi] = t.fmis[t.fmis.length-1];
        }
        t.fmis.length--;
    }

    function hasField(bytes32 tsKey, bytes32 tKey, bytes32 fKey) constant public returns (bool) {
        return _isSet(tsm[tsKey].tm[tKey].fm[fKey]);
    }

    function getFieldName(bytes32 tsKey, bytes32 tKey, bytes32 fKey) constant public returns (string) {
        var f = tsm[tsKey].tm[tKey].fm[fKey];
        require(_isSet(f));
        return f.name;
    }

}

contract TiesDB is TiesDBTablespace, TiesDBTable, TiesDBField {
    function getVersion() constant public returns (string) {
        return "0.1.0 alpha";
    }
}

contract Debug is TiesDB, TiesDBRestrictionsOwner {

    using TiesLibString for string;

    function registerOwner(string tsName) public {
        registerOwner(tsName.hash(), msg.sender);
    }
    function canCreateTablespace(string tsName) public constant returns (bool) {
        return canCreateTablespace(tsName.hash(), msg.sender);
    }
    function canDeleteTablespace(string tsName) public constant returns (bool) {
        return canDeleteTablespace(tsName.hash(), msg.sender);
    }
    function canCreateTable(string tsName, string tName) public constant returns (bool) {
        return canCreateTable(tsName.hash(), tName.hash(), msg.sender);
    }
    function canCreateTable(bytes32 tsKey, string tName) public constant returns (bool) {
        return canCreateTable(tsKey, tName.hash(), msg.sender);
    }
    function canDeleteTable(string tsName, string tName) public constant returns (bool) {
        return canDeleteTable(tsName.hash(), tName.hash(), msg.sender);
    }
    function canDeleteTable(bytes32 tsKey, string tName) public constant returns (bool) {
        return canDeleteTable(tsKey, tName.hash(), msg.sender);
    }

    function createTablespace(string tsName) public returns (bytes32) {
        return createTablespace(tsName, TiesDBRestrictions(this));
    }
    function deleteTablespace(string tsName) public {
        deleteTablespace(tsName.hash());
    }
    function hasTablespace(string tsName) constant public returns (bool) {
        return hasTablespace(tsName.hash());
    }
    function getTablespaceTablesKeys(string tsName) constant public returns (bytes32[]) {
        return getTablespaceTablesKeys(tsName.hash());
    }

    function createTable(string tsName, string tName) public returns (bytes32) {
        return createTable(tsName.hash(), tName);
    }
    function deleteTable(string tsName, string tName) public {
        deleteTable(tsName.hash(), tName.hash());
    }
    function deleteTable(bytes32 tsKey, string tName) public {
        deleteTable(tsKey, tName.hash());
    }
    function hasTable(string tsName, string tName) constant public returns (bool) {
        return hasTable(tsName.hash(), tName.hash());
    }
    function hasTable(bytes32 tsKey, string tName) constant public returns (bool) {
        return hasTable(tsKey, tName.hash());
    }
    function getTableFieldsKeys(string tsName, string tName) constant public returns (bytes32[]) {
        return getTableFieldsKeys(tsName.hash(), tName.hash());
    }

    function createField(string tsName, string tName, string fName) public returns (bytes32) {
        return createField(tsName.hash(), tName.hash(), fName);
    }
    function createField(bytes32 tsKey, string tName, string fName) public returns (bytes32) {
        return createField(tsKey, tName.hash(), fName);
    }
    function deleteField(string tsName, string tName, string fName) public {
        deleteField(tsName.hash(), tName.hash(), fName.hash());
    }
    function deleteField(bytes32 tsKey, string tName, string fName) public {
        deleteField(tsKey, tName.hash(), fName.hash());
    }
    function hasField(string tsName, string tName, string fName) constant public returns (bool) {
        return hasField(tsName.hash(), tName.hash(), fName.hash());
    }
    function hasField(bytes32 tsKey, string tName, string fName) constant public returns (bool) {
        return hasField(tsKey, tName.hash(), fName.hash());
    }
}