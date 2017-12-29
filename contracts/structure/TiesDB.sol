pragma solidity ^0.4.15;

import "zeppelin/contracts/ownership/Ownable.sol";
import "./TLStorage.sol";
import "./TLTblspace.sol";
import "./TLTable.sol";
import "./TLField.sol";
import "./TLTrigger.sol";
import "./TLNode.sol";


contract TiesDB is Ownable {
    
    using TLField for TLType.Field;
    using TLTrigger for TLType.Trigger;
    using TLTable for TLType.Table;
    using TLTblspace for TLType.Tablespace;
    using TLStorage for TLType.Storage;
    using TLNode for TLType.Node;

    TLType.Storage private s;
    address private registry; //The registry contract that allows node manipulation

    function setRegistry (address _registry) onlyOwner public {
        registry = _registry;
    }

    function createNode(address _node) onlyRegistry public {
        s.createNode(_node);
    }

    function queueNode(address _node) onlyRegistry public {
        var n = s.nm[_node];
        require(!n.isEmpty());
        n.queue(s);
    }

    function unqueueNode(address _node) onlyRegistry public {
        var n = s.nm[_node];
        require(!n.isEmpty());
        n.unqueue(s);
    }

    function createTablespace(string tsName, TiesDBRestrictions rs) external returns (bytes32) {
        return s.createTablespace(tsName, rs);
    }

    function deleteTablespace(bytes32 tsKey) external {
        s.deleteTablespace(tsKey);
    }

    function createField(bytes32 tsKey, bytes32 tKey,
        string fName, string fType, bytes fDefault) external returns (bytes32) {
        return s.tsm[tsKey].tm[tKey].createField(fName, fType, fDefault);
    }

    function createTrigger(bytes32 tsKey, bytes32 tKey,
        string trName, bytes payload) external returns (bytes32) {
        return s.tsm[tsKey].tm[tKey].createTrigger(trName, payload);
    }

    function getTablespaceKeys() public constant returns (bytes32[]) {
        return s.getTablespaceKeys();
    }

    function hasTablespace(bytes32 tsKey) public constant returns (bool) {
        return s.hasTablespace(tsKey);
    }
    
    function getTablespaceName(bytes32 tsKey) public constant returns (string) {
        return s.tsm[tsKey].getTablespaceName();
    }

    function getTablespaceTablesKeys(bytes32 tsKey) public constant returns (bytes32[]) {
        return s.tsm[tsKey].getTablesKeys();
    }

    function createTable(bytes32 tsKey, string tName) public returns (bytes32) {
        var tKey = s.tsm[tsKey].createTable(tName);
        s.table_to_tablespace[tKey] = tsKey;
    }

    function deleteTable(bytes32 tsKey, bytes32 tKey) public {
        s.tsm[tsKey].deleteTable(tKey);
        delete s.table_to_tablespace[tKey];
    }

    function hasTable(bytes32 tsKey, bytes32 tKey) public constant returns (bool) {
        return s.tsm[tsKey].hasTable(tKey);
    }

    function getTableName(bytes32 tsKey, bytes32 tKey) public constant returns (string) {
        return s.tsm[tsKey].tm[tKey].getTableName();
    }

    function getTableFieldsKeys(bytes32 tsKey, bytes32 tKey) public constant returns (bytes32[]) {
        return s.tsm[tsKey].tm[tKey].getFieldsKeys();
    }

    function deleteField(bytes32 tsKey, bytes32 tKey, bytes32 fKey) public returns (bytes32) {
        s.tsm[tsKey].tm[tKey].deleteField(fKey);
    }

    function hasField(bytes32 tsKey, bytes32 tKey, bytes32 fKey) public constant returns (bool) {
        return s.tsm[tsKey].tm[tKey].hasField(fKey);
    }

    function getFieldName(bytes32 tsKey, bytes32 tKey, bytes32 fKey) public constant returns (string) {
        return s.tsm[tsKey].tm[tKey].fm[fKey].getFieldName();
    }

    function deleteTrigger(bytes32 tsKey, bytes32 tKey, bytes32 trKey) public returns (bytes32) {
        s.tsm[tsKey].tm[tKey].deleteTrigger(trKey);
    }

    function hasTrigger(bytes32 tsKey, bytes32 tKey, bytes32 trKey) public constant returns (bool) {
        return s.tsm[tsKey].tm[tKey].hasTrigger(trKey);
    }

    function getTriggerName(bytes32 tsKey, bytes32 tKey, bytes32 trKey) public constant returns (string) {
        return s.tsm[tsKey].tm[tKey].trm[trKey].getTriggerName();
    }

    modifier onlyRegistry() { require(msg.sender == registry); _; }

}
