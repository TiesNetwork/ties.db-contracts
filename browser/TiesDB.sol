pragma solidity ^0.4.15;

import "browser/TLStorage.sol";
import "browser/TLTblspace.sol";
import "browser/TLTable.sol";
import "browser/TLField.sol";

contract TiesDB {
    
    using TLField for TLType.Field;
    using TLTable for TLType.Table;
    using TLTblspace for TLType.Tablespace;
    using TLStorage for TLType.Storage;

    TLType.Storage private s;

    function createTablespace(string tsName, TiesDBRestrictions rs) external returns (bytes32) {
        return s.createTablespace(tsName, rs);
    }

    function deleteTablespace(bytes32 tsKey) external {
        s.deleteTablespace(tsKey);
    }

    function getTablespaceKeys() constant external returns (bytes32[]) {
        return s.getTablespaceKeys();
    }

    function hasTablespace(bytes32 tsKey) constant external returns (bool) {
        return s.hasTablespace(tsKey);
    }
    
    function getTablespaceName(bytes32 tsKey) constant external returns (string) {
        return s.tsm[tsKey].getTablespaceName();
    }

    function getTablespaceTablesKeys(bytes32 tsKey) constant external returns (bytes32[]) {
        return s.tsm[tsKey].getTablesKeys();
    }

    function createTable(bytes32 tsKey, string tName) external returns (bytes32) {
        return s.tsm[tsKey].createTable(tName);
    }

    function deleteTable(bytes32 tsKey, bytes32 tKey) external {
        s.tsm[tsKey].deleteTable(tKey);
    }

    function hasTable(bytes32 tsKey, bytes32 tKey) constant external returns (bool) {
        return s.tsm[tsKey].hasTable(tKey);
    }

    function getTableName(bytes32 tsKey, bytes32 tKey) constant external returns (string) {
        return s.tsm[tsKey].tm[tKey].getTableName();
    }

    function getTableFieldsKeys(bytes32 tsKey, bytes32 tKey) constant external returns (bytes32[]) {
        return s.tsm[tsKey].tm[tKey].getFieldsKeys();
    }

    function createField(bytes32 tsKey, bytes32 tKey, string fName) external returns (bytes32) {
        return s.tsm[tsKey].tm[tKey].createField(fName);
    }

    function deleteField(bytes32 tsKey, bytes32 tKey, bytes32 fKey) external returns (bytes32) {
        s.tsm[tsKey].tm[tKey].deleteField(fKey);
    }

    function hasField(bytes32 tsKey, bytes32 tKey, bytes32 fKey) constant external returns (bool) {
        return s.tsm[tsKey].tm[tKey].hasField(fKey);
    }

    function getFieldName(bytes32 tsKey, bytes32 tKey, bytes32 fKey) constant external returns (string) {
        return s.tsm[tsKey].tm[tKey].fm[fKey].getFieldName();
    }

}

import "browser/Util.sol";
import "browser/TiesDBAPI.sol";

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
        return canCreateTablespace(tsName, owner);
    }

    function canCreateTable(string tsName, string tName, address owner) public constant returns (bool) {
        require(!tsName.isEmpty() && !tName.isEmpty());
        return canCreateTablespace(tsName, owner);
    }

    function canDeleteTable(string tsName, string tName, address owner) public constant returns (bool) {
        require(!tsName.isEmpty() && !tName.isEmpty());
        return canCreateTablespace(tsName, owner);
    }

    function canCreateField(string tsName, string tName, string fName, address owner) public constant returns (bool) {
        require(!tsName.isEmpty() && !tName.isEmpty() && !fName.isEmpty());
        return canCreateTablespace(tsName, owner);
    }
    function canDeleteField(string tsName, string tName, string fName, address owner) public constant returns (bool) {
        require(!tsName.isEmpty() && !tName.isEmpty() && !fName.isEmpty());
        return canCreateTablespace(tsName, owner);
    }
}