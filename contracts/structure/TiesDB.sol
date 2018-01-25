pragma solidity ^0.4.15;

import "zeppelin/contracts/ownership/Ownable.sol";
import "./TLStorage.sol";
import "./TLTblspace.sol";
import "./TLTable.sol";
import "./TLField.sol";
import "./TLTrigger.sol";
import "./TLNode.sol";
import "./TLIndex.sol";


contract TiesDB is Ownable, TiesDBNodes {
    
    using TLField for TLType.Field;
    using TLTrigger for TLType.Trigger;
    using TLTable for TLType.Table;
    using TLTblspace for TLType.Tablespace;
    using TLStorage for TLType.Storage;
    using TLNode for TLType.Node;
    using TLIndex for TLType.Index;

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

    function createField(bytes32 tKey,
        string fName, string fType, bytes fDefault) external returns (bytes32) {
        return s.getTable(tKey).createField(fName, fType, fDefault);
    }

    function getStorage() public view returns (bytes32[] tablespaces, address[] nodes) {
        return s.export();
    }

    function hasTablespace(bytes32 tsKey) public constant returns (bool) {
        return s.hasTablespace(tsKey);
    }

    function getTablespaceName(bytes32 tsKey) public constant returns (string) {
        return s.tsm[tsKey].getName();
    }

    function getTablespace(bytes32 tsKey) public constant returns (string name, address rs, bytes32[] tables) {
        return s.tsm[tsKey].export();
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

    function hasTable(bytes32 tKey) public constant returns (bool) {
        return s.table_to_tablespace[tKey] != 0;
    }

    function getTableName(bytes32 tKey) public constant returns (string) {
        return s.getTable(tKey).getName();
    }

    function getTable(bytes32 tKey) public constant returns (string name, string tsName,
        bytes32[] fields, bytes32[] triggers, bytes32[] indexes, uint32 replicas, uint32 ranges, address[] nodes) {
        return s.getTable(tKey).export();
    }

    function deleteField(bytes32 tKey, bytes32 fKey) public {
        s.getTable(tKey).deleteField(fKey);
    }

    function hasField(bytes32 tKey, bytes32 fKey) public constant returns (bool) {
        return s.getTable(tKey).hasField(fKey);
    }

    function getFieldName(bytes32 tKey, bytes32 fKey) public constant returns (string) {
        return s.getTable(tKey).fm[fKey].getName();
    }

    function getField(bytes32 tKey, bytes32 fKey) public constant returns (string name,
        string fType, bytes def) {
        return s.getTable(tKey).fm[fKey].export();
    }

    function createTrigger(bytes32 tKey,
        string trName, bytes payload) external returns (bytes32) {
        return s.getTable(tKey).createTrigger(trName, payload);
    }

    function deleteTrigger(bytes32 tKey, bytes32 trKey) public {
        s.getTable(tKey).deleteTrigger(trKey);
    }

    function hasTrigger(bytes32 tKey, bytes32 trKey) public view returns (bool) {
        return s.getTable(tKey).hasTrigger(trKey);
    }

    function getTriggerName(bytes32 tKey, bytes32 trKey) public view returns (string) {
        return s.getTable(tKey).trm[trKey].getName();
    }

    function getTrigger(bytes32 tKey, bytes32 trKey) public view returns (string name, bytes payload) {
        return s.getTable(tKey).trm[trKey].export();
    }

    function createIndex(bytes32 tKey, string iName, uint8 iType, bytes32[] fields) external returns (bytes32) {
        return s.getTable(tKey).createIndex(iName, iType, fields);
    }

    function deleteIndex(bytes32 tKey, bytes32 iKey) public {
        s.getTable(tKey).deleteIndex(iKey);
    }

    function hasIndex(bytes32 tKey, bytes32 iKey) public view returns (bool) {
        return s.getTable(tKey).hasIndex(iKey);
    }

    function getIndexName(bytes32 tKey, bytes32 iKey) public view returns (string) {
        return s.getTable(tKey).im[iKey].getName();
    }

    function getIndex(bytes32 tKey, bytes32 iKey) public view returns (string name, uint8 iType, bytes32[] fields) {
        return s.getTable(tKey).im[iKey].export();
    }

    modifier onlyRegistry() { require(msg.sender == registry); _; }

    function getNodes() public view returns (address[]) {
        return s.nmis;
    }

    function getNode(address node) public view returns (bool inQueue, bytes32[] tables) {
        return s.nm[node].export();
    }

    function getTableNodes(bytes32 tKey) public view returns (address[]) {
        return s.getTable(tKey).nodes;
    }

    function getNodeTableRanges(address node, bytes32 tKey) public view returns (uint64[]) {
        var n = s.nm[node];
        return n.getRangesPack(tKey);
    }

    function distribute(bytes32 tKey, uint32 ranges, uint32 replicas) public {
        require(uint(s.getTable(tKey).getPrimaryIndex()) != 0);
        s.distributeRanges(tKey, ranges, replicas);
    }

    function tableToTablespace(bytes32 tKey) public view returns (bytes32) {
        return s.table_to_tablespace[tKey];
    }



}
