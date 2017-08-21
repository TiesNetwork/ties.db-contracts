pragma solidity ^0.4.15;

import "browser/Util.sol";

library TLType {

    struct Field {
        FieldRef flr;
        uint256 fli;
        string name;
    }

    struct Table {
        TableRef tbr;
        string name;
        uint256 tbi;
        bytes32[] fli;
        mapping(bytes32 => Field) flm;
    }

    struct Tablespace {
        TablespaceRef tsr;
        TiesDBRestrictions rs;
        string name;
        uint256 tsi;
        bytes32[] tbi;
        mapping(bytes32 => Table) tbm;
    }

    struct Storage {
        StorageRef str;
        bytes32[] tsi;
        mapping(bytes32 => TLType.Tablespace) tsm;
    }

    struct StorageRef {
        Database db;
    }

    struct TablespaceRef {
        StorageRef str;
        bytes32 tsKey;
    }

    struct TableRef {
        TablespaceRef tsr;
        bytes32 tbKey;
    }

    struct FieldRef {
        TableRef tbr;
        bytes32 flKey;
    }
}

contract Database {

    using TiesLibString for string;

    using TLField for TLType.Field;
    using TLTable for TLType.Table;
    using TLTablespace for TLType.Tablespace;
    using TLStorage for TLType.Storage;
    using TLStorageRef for TLType.Storage;

    TLType.Storage internal st = TLType.Storage({str: TLType.StorageRef({db: this}), tsi: new bytes32[](0)});

}

library TLStorageRef {

    function getTablespace(TLType.Storage storage st, bytes32 tsKey) constant public returns (TLType.Tablespace storage) {
        return st.tsm[tsKey];
    }
    function getTable(TLType.Storage storage st, bytes32 tsKey, bytes32 tbKey) constant public returns (TLType.Table storage) {
        return st.tsm[tsKey].tbm[tbKey];
    }
    function getField(TLType.Storage storage st, bytes32 tsKey, bytes32 tbKey, bytes32 flKey) constant public returns (TLType.Field storage) {
        return st.tsm[tsKey].tbm[tbKey].flm[flKey];
    }
    function getStorage(TLType.Storage storage st, TLType.StorageRef storage str) constant public returns (TLType.Storage storage) {
        require(address(str.db) == address(this));
        return st;
    }
    function getTablespace(TLType.Storage storage st, TLType.TablespaceRef storage tsr) constant public returns (TLType.Tablespace storage) {
        return getStorage(st, tsr.str).tsm[tsr.tsKey];
    }
    function getTable(TLType.Storage storage st, TLType.TableRef storage tbr) constant public returns (TLType.Table storage) {
        return getStorage(st, tbr.tsr.str).tsm[tbr.tsr.tsKey].tbm[tbr.tbKey];
    }
    function getField(TLType.Storage storage st, TLType.FieldRef storage flr) constant public returns (TLType.Field storage) {
        return getStorage(st, flr.tbr.tsr.str).tsm[flr.tbr.tsr.tsKey].tbm[flr.tbr.tbKey].flm[flr.flKey];
    }
}

library TLStorage {

    using TiesLibString for string;
    using TLTablespace for TLType.Tablespace;

    function isSet(TLType.Storage storage st) constant public returns (bool) {
        return address(st.str.db) == address(this);
    }
    function getTablespaceIndex(TLType.Storage storage st, uint256 tsi) constant public returns (bytes32 tsKey) {
        return st.tsi[tsi];
    }
    function getTablespaceIndexLength(TLType.Storage storage st) constant public returns (uint256 tsi) {
        return st.tsi.length;
    }
    // Mutators
    function createTablespace(TLType.Storage storage st, string tsName, TiesDBRestrictions rs) public returns (bytes32) {
        var tsKey = tsName.hash();
        require(!st.tsm[tsKey].isSet() && rs.canCreateTablespace(tsName, msg.sender));
        st.tsm[tsKey] = TLType.Tablespace({tsr: TLType.TablespaceRef({str: st.str, tsKey: tsKey}), rs: rs, name: tsName, tsi: st.tsi.push(tsKey) - 1, tbi: new bytes32[](0)});
        return tsKey;
    }
    function deleteTablespace(TLType.Storage storage st, bytes32 tsKey) public {
        var ts = st.tsm[tsKey];
        require(ts.isSet() && ts.tbi.length == 0 && ts.rs.canDeleteTablespace(ts.name, msg.sender));
        if(st.tsi.length > 1){
            var tail = st.tsi[st.tsi.length];
            st.tsi[ts.tsi] = tail;
            st.tsm[tail].tsi = ts.tsi;
        }
        st.tsi.length--;
        delete st.tsm[tsKey];
    }
}

library TLTablespace {

    using TiesLibString for string;
    using TLTable for TLType.Table;

    function isSet(TLType.Tablespace storage ts) constant public returns (bool) {
        return address(ts.tsr.str.db) == address(this);
    }
    function getTableIndex(TLType.Tablespace storage ts, uint256 tbi) constant public returns (bytes32 tbKey) {
        return ts.tbi[tbi];
    }
    function getTableIndexLength(TLType.Tablespace storage ts) constant public returns (uint256 tbi) {
        return ts.tbi.length;
    }
    // Mutators
    function createTable(TLType.Tablespace storage ts, string tbName) public returns (bytes32) {
        var tbKey = tbName.hash();
        require(!ts.tbm[tbKey].isSet() && ts.rs.canCreateTable(ts.name, tbName, msg.sender));
        ts.tbm[tbKey] = TLType.Table({tbr: TLType.TableRef({tsr: ts.tsr, tbKey: tbKey}), name: tbName, tbi: ts.tbi.push(tbKey) - 1, fli: new bytes32[](0)});
        return tbKey;
    }
    function deleteTable(TLType.Tablespace storage ts, bytes32 tbKey) public {
        var tb = ts.tbm[tbKey];
        require(tb.isSet() && tb.fli.length == 0 && ts.rs.canDeleteTable(ts.name, tb.name, msg.sender));
        if(ts.tbi.length > 1){
            var tail = ts.tbi[ts.tbi.length - 1];
            ts.tbi[ts.tsi] = tail;
            ts.tbm[tail].tbi = ts.tsi;
        }
        ts.tbi.length--;
        delete ts.tbm[tbKey];
    }
}

library TLTable {

    using TiesLibString for string;
    using TLField for TLType.Field;
    using TLStorageRef for TLType.Storage;

    function isSet(TLType.Table storage tb) constant public returns (bool){
        return address(tb.tbr.tsr.str.db) == address(this);
    }
    function getFieldIndex(TLType.Table storage tb, uint256 fli) constant public returns (bytes32 flKey) {
        return tb.fli[fli];
    }
    function getFieldIndexLength(TLType.Table storage tb) constant public returns (uint256 fli) {
        return tb.fli.length;
    }
    // Mutators
    function createField(TLType.Storage storage st, TLType.TableRef storage tbr,  string flName) public returns (bytes32) {
        var flKey = flName.hash();
        var ts = st.getTablespace(tbr.tsr);
        var tb = ts.tbm[tbr.tbKey];
        require(!tb.flm[flKey].isSet() && ts.rs.canCreateField(ts.name, tb.name, flName, msg.sender));
        tb.flm[flKey] = TLType.Field({flr: TLType.FieldRef({tbr: tb.tbr, flKey: flKey}), name: flName, fli: tb.fli.push(flKey) - 1});
        return flKey;
    }
    function deleteField(TLType.Storage storage st, TLType.TableRef storage tbr, bytes32 flKey) public {
        var ts = st.getTablespace(tbr.tsr);
        var tb = ts.tbm[tbr.tbKey];
        var fl = tb.flm[flKey];
        require(fl.isSet() && ts.rs.canDeleteField(ts.name, tb.name, fl.name, msg.sender));
        if(tb.fli.length > 1){
            var tail = tb.fli[tb.fli.length - 1];
            tb.fli[tb.tbi] = tail;
            tb.flm[tail].fli = tb.tbi;
        }
        tb.fli.length--;
        delete tb.flm[flKey];
    }
}

library TLField {
    function isSet(TLType.Field storage fl) constant public returns (bool){
        return address(fl.flr.tbr.tsr.str.db) == address(this);
    }
}

contract TiesDB is Database {
    function getTablespaceIndex(uint256 tsi) constant public returns (bytes32 tsKey) {
        return st.getTablespaceIndex(tsi);
    }
    function getTablespaceIndexLength() constant public returns (uint256 tsi) {
        return st.getTablespaceIndexLength();
    }
    function hasTablespace(bytes32 tsKey) constant public returns (bool) {
        return st.getTablespace(tsKey).isSet();
    }
    function getTablespaceName(bytes32 tsKey) constant public returns (string tsName) {
        return st.getTablespace(tsKey).name;
    }
    function getTableIndex(bytes32 tsKey, uint256 tbi) constant public returns (bytes32 tbKey) {
        return st.getTablespace(tsKey).getTableIndex(tbi);
    }
    function getTableIndexLength(bytes32 tsKey) constant public returns (uint256 tbi) {
        return st.getTablespace(tsKey).getTableIndexLength();
    }
    function hasTable(bytes32 tsKey, bytes32 tbKey) constant public returns (bool) {
        return st.getTable(tsKey,tbKey).isSet();
    }
    function getTableName(bytes32 tsKey, bytes32 tbKey) constant public returns (string tbName) {
        return st.getTable(tsKey,tbKey).name;
    }
    // Mutators
    function createTablespace(string tsName, TiesDBRestrictions rs) public returns (bytes32 tsKey) {
        return st.createTablespace(tsName, rs);
    }
    function deleteTablespaces(bytes32[] tsKeys) public {
        for(uint256 i = 0; i < tsKeys.length; i++){
            st.deleteTablespace(tsKeys[i]);
        }
    }
    function createTable(bytes32 tsKey, string tbName) public returns (bytes32 tbKey) {
        return st.getTablespace(tsKey).createTable(tbName);
    }
    function deleteTables(bytes32 tsKey, bytes32[] tbKeys) public {
        var ts = st.getTablespace(tsKey);
        for(uint256 i = 0; i < tbKeys.length; i++){
            ts.deleteTable(tbKeys[i]);
        }
    }
}

contract TiesDBRestrictions {
    function canCreateTablespace(string tsName, address owner) public constant returns (bool);
    function canDeleteTablespace(string tsName, address owner) public constant returns (bool);
    function canCreateTable(string tsName, string tName, address owner) public constant returns (bool);
    function canDeleteTable(string tsName, string tName, address owner) public constant returns (bool);
    function canCreateField(string tsName, string tName, string fName, address owner) public constant returns (bool);
    function canDeleteField(string tsName, string tName, string fName, address owner) public constant returns (bool);
}

contract TiesDBRestrictionsOwner {

    using TiesLibString for string;

    mapping(bytes32 => mapping(address => bool)) private tm;

    function registerOwner(string tsName, address owner) public {
        require(!tm[tsName.hash()][owner]);
        tm[tsName.hash()][owner] = true;
    }

    function canCreateTablespace(string tsName, address owner) public constant returns (bool) {
        return tm[tsName.hash()][owner];
    }

    function canDeleteTablespace(string tsName, address owner) public constant returns (bool) {
        return canCreateTablespace(tsName, owner);
    }

    function canCreateTable(string tsName, string, address owner) public constant returns (bool) {
        return canCreateTablespace(tsName, owner);
    }

    function canDeleteTable(string tsName, string, address owner) public constant returns (bool) {
        return canCreateTablespace(tsName, owner);
    }

    function canCreateField(string tsName, string, string, address owner) public constant returns (bool) {
        return canCreateTablespace(tsName, owner);
    }
    function canDeleteField(string tsName, string, string, address owner) public constant returns (bool) {
        return canCreateTablespace(tsName, owner);
    }
}