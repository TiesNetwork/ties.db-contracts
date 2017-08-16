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
    function canCreateTablespace(string tsName, address owner) public constant returns (bool);
    function canDeleteTablespace(string tsName, address owner) public constant returns (bool);
    function canCreateTable(string tsName, string tName, address owner) public constant returns (bool);
    function canDeleteTable(string tsName, string tName, address owner) public constant returns (bool);
    function canCreateField(string tsName, string tName, string fName, address owner) public constant returns (bool);
    function canDeleteField(string tsName, string tName, string fName, address owner) public constant returns (bool);
}

contract TiesDBRestrictionsOwner {

    using TiesLibString for string;
    using TiesLibAddress for address;

    mapping(bytes32 => address) private tsm;

    function registerOwner(string tsName, address owner) public {
        require(!tsName.isEmpty());
        require(tsm[tsName.hash()].isFree());
        tsm[tsName.hash()] = owner;
    }

    function canCreateTablespace(string tsName, address owner) public constant returns (bool) {
        require(!tsName.isEmpty());
        return tsm[tsName.hash()] == owner;
    }

    function canDeleteTablespace(string tsName, address owner) public constant returns (bool) {
        require(!tsName.isEmpty());
        return tsm[tsName.hash()] == owner;
    }

    function canCreateTable(string tsName, string tName, address owner) public constant returns (bool) {
        require(!tsName.isEmpty() && !tName.isEmpty());
        return tsm[tsName.hash()] == owner;
    }

    function canDeleteTable(string tsName, string tName, address owner) public constant returns (bool) {
        require(!tsName.isEmpty() && !tName.isEmpty());
        return tsm[tsName.hash()] == owner;
    }

    function canCreateField(string tsName, string tName, string fName, address owner) public constant returns (bool) {
        require(!tsName.isEmpty() && !tName.isEmpty() && !fName.isEmpty());
        return tsm[tsName.hash()] == owner;
    }
    function canDeleteField(string tsName, string tName, string fName, address owner) public constant returns (bool) {
        require(!tsName.isEmpty() && !tName.isEmpty() && !fName.isEmpty());
        return tsm[tsName.hash()] == owner;
    }
}

library TiesDBLibField {

    using TiesLibAddress for address;
    using TiesDBLibField for TiesDBLibField.Field;

    struct Field {
        TiesDBLibTable.Table t;
        string name;
        uint256 fmi;
    }

    function isSet(Field storage f) constant internal returns (bool) {
        return !address(f.t.ts.rs).isFree();
    }

    function getFieldName(Field storage f) constant internal returns (string) {
        require(f.isSet());
        return f.name;
    }
}

library TiesDBLibTable {

    using TiesLibString for string;
    using TiesLibAddress for address;
    using TiesDBLibTable for TiesDBLibTable.Table;
    using TiesDBLibField for TiesDBLibField.Field;

    struct Table {
        TiesDBLibTablespace.Tablespace ts;
        string name;
        uint256 tmi;
        mapping(bytes32 => TiesDBLibField.Field) fm;
        bytes32[] fmis;
    }

    function isSet(Table storage t) constant internal returns (bool) {
        return !address(t.ts.rs).isFree();
    }

    function getTableName(Table storage t) constant internal returns (string) {
        require(t.isSet());
        return t.name;
    }

    function getTableFieldsKeys(Table storage t) constant internal returns (bytes32[]) {
        require(t.isSet());
        return t.fmis;
    }

    function createField(Table storage t, string fName) internal returns (bytes32) {
        var fKey = fName.hash();
        require(!t.hasField(fKey) && t.ts.rs.canCreateField(t.ts.name, t.name, fName, msg.sender));
        t.fm[fKey] = TiesDBLibField.Field({name: fName, t: t, fmi: t.fmis.length});
        t.fmis.push(fKey);
        return fKey;
    }

    function deleteField(Table storage t, bytes32 fKey) internal returns (bytes32) {
        var f = t.fm[fKey];
        require(f.isSet() && t.ts.rs.canDeleteField(t.ts.name, t.name, f.name, msg.sender));
        if(t.fmis.length > 1){
            t.fmis[f.fmi] = t.fmis[t.fmis.length-1];
        }
        t.fmis.length--;
    }

    function hasField(Table storage t, bytes32 fKey) constant internal returns (bool) {
        return t.fm[fKey].isSet();
    }
}

library TiesDBLibTablespace {

    using TiesLibString for string;
    using TiesLibAddress for address;
    using TiesDBLibTable for TiesDBLibTable.Table;
    using TiesDBLibTablespace for TiesDBLibTablespace.Tablespace;

    struct Tablespace {
        TiesDBRestrictions rs;
        string name;
        uint256 tsmi;
        mapping(bytes32 => TiesDBLibTable.Table) tm;
        bytes32[] tmis;
    }

    function isSet(Tablespace storage ts) constant internal returns (bool) {
        return !address(ts.rs).isFree();
    }
    
    function getTablespaceName(Tablespace storage ts) constant internal returns (string) {
        require(ts.isSet());
        return ts.name;
    }

    function getTablespaceTablesKeys(Tablespace storage ts) constant internal returns (bytes32[]) {
        require(ts.isSet());
        return ts.tmis;
    }

    function createTable(Tablespace storage ts, string tName) internal returns (bytes32) {
        var tKey = tName.hash();
        require(!ts.hasTable(tKey) && ts.rs.canCreateTable(ts.name, tName, msg.sender));
        ts.tm[tKey] = TiesDBLibTable.Table({name: tName, ts: ts, tmi: ts.tmis.length, fmis: new bytes32[](0)});
        ts.tmis.push(tKey);
        return tKey;
    }

    function deleteTable(Tablespace storage ts, bytes32 tKey) internal {
        var t = ts.tm[tKey];
        require(t.isSet() && ts.rs.canDeleteTable(ts.name, t.name, msg.sender));
        if(ts.tmis.length > 1){
            ts.tmis[t.tmi] = ts.tmis[ts.tmis.length-1];
        }
        ts.tmis.length--;
    }

    function hasTable(Tablespace storage ts, bytes32 tKey) constant internal returns (bool) {
        return ts.tm[tKey].isSet();
    }
}

library TiesDBLibStorage {

    using TiesLibString for string;
    using TiesLibAddress for address;
    using TiesDBLibStorage for TiesDBLibStorage.Storage;
    using TiesDBLibTablespace for TiesDBLibTablespace.Tablespace;

    struct Storage {
        mapping(bytes32 => TiesDBLibTablespace.Tablespace) tsm;
        bytes32[] tsmis;
    }

    function createTablespace(Storage storage s, string tsName, TiesDBRestrictions rs) internal returns (bytes32) {
        var tsKey = tsName.hash();
        require(!s.hasTablespace(tsKey) && rs.canCreateTablespace(tsName, msg.sender));
        s.tsm[tsName.hash()] = TiesDBLibTablespace.Tablespace({name: tsName, rs: rs, tsmi: s.tsmis.length, tmis: new bytes32[](0)});
        s.tsmis.push(tsKey);
        return tsKey;
    }

    function deleteTablespace(Storage storage s, bytes32 tsKey) internal {
        var ts = s.tsm[tsKey];
        require(ts.isSet() && ts.rs.canDeleteTablespace(ts.name, msg.sender));
        if(s.tsmis.length > 1){
            s.tsmis[ts.tsmi] = s.tsmis[s.tsmis.length-1];
        }
        s.tsmis.length--;
    }

    function hasTablespace(Storage storage s, bytes32 tsKey) constant internal returns (bool) {
        return s.tsm[tsKey].isSet();
    }

    function getTablespaceKeys(Storage storage s) constant internal returns (bytes32[]) {
        return s.tsmis;
    }
}

contract TiesDB {
    
    using TiesDBLibStorage for TiesDBLibStorage.Storage;
    using TiesDBLibTablespace for TiesDBLibTablespace.Tablespace;
    using TiesDBLibTable for TiesDBLibTable.Table;
    using TiesDBLibField for TiesDBLibField.Field;

    TiesDBLibStorage.Storage private s;

    function createTablespace(string tsName, TiesDBRestrictions rs) public returns (bytes32) {
        return s.createTablespace(tsName, rs);
    }

    function deleteTablespace(bytes32 tsKey) public {
        s.deleteTablespace(tsKey);
    }

    function getTablespaceKeys() constant public returns (bytes32[]) {
        return s.getTablespaceKeys();
    }

    function hasTablespace(bytes32 tsKey) constant public returns (bool) {
        return s.hasTablespace(tsKey);
    }
    
    function getTablespaceName(bytes32 tsKey) constant public returns (string) {
        return s.tsm[tsKey].getTablespaceName();
    }

    function getTablespaceTablesKeys(bytes32 tsKey) constant public returns (bytes32[]) {
        return s.tsm[tsKey].getTablespaceTablesKeys();
    }

    function createTable(bytes32 tsKey, string tName) public returns (bytes32) {
        return s.tsm[tsKey].createTable(tName);
    }

    function deleteTable(bytes32 tsKey, bytes32 tKey) public {
        s.tsm[tsKey].deleteTable(tKey);
    }

    function hasTable(bytes32 tsKey, bytes32 tKey) constant public returns (bool) {
        return s.tsm[tsKey].hasTable(tKey);
    }

    function getTableName(bytes32 tsKey, bytes32 tKey) constant public returns (string) {
        return s.tsm[tsKey].tm[tKey].getTableName();
    }

    function getTableFieldsKeys(bytes32 tsKey, bytes32 tKey) constant public returns (bytes32[]) {
        return s.tsm[tsKey].tm[tKey].getTableFieldsKeys();
    }

    function createField(bytes32 tsKey, bytes32 tKey, string fName) public returns (bytes32) {
        return s.tsm[tsKey].tm[tKey].createField(fName);
    }

    function deleteField(bytes32 tsKey, bytes32 tKey, bytes32 fKey) public returns (bytes32) {
        s.tsm[tsKey].tm[tKey].deleteField(fKey);
    }

    function hasField(bytes32 tsKey, bytes32 tKey, bytes32 fKey) constant public returns (bool) {
        return s.tsm[tsKey].tm[tKey].hasField(fKey);
    }

    function getFieldName(bytes32 tsKey, bytes32 tKey, bytes32 fKey) constant public returns (string) {
        return s.tsm[tsKey].tm[tKey].fm[fKey].getFieldName();
    }
}

contract Debug is TiesDB, TiesDBRestrictionsOwner {

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