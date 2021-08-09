pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./TLStorage.sol";
import "./TLTblspace.sol";
import "./TLTable.sol";
import "./TLField.sol";
import "./TLTrigger.sol";
import "./TLNode.sol";
import "./TLIndex.sol";


contract TiesDB is Ownable, TiesDBNodes, TiesDBSchema {
    
    using TLField for TLType.Field;
    using TLTrigger for TLType.Trigger;
    using TLTable for TLType.Table;
    using TLTblspace for TLType.Tablespace;
    using TLStorage for TLType.Storage;
    using TLNode for TLType.Node;
    using TLIndex for TLType.Index;

    TLType.Storage private s;
    address private registry; //The registry contract that allows node manipulation

    function setRegistry (address registryAddress) onlyOwner public {
        registry = registryAddress;
    }

    function createNode(address nodeAddress) onlyRegistry public {
        s.createNode(nodeAddress);
    }

    function queueNode(address nodeAddress) onlyRegistry public {
        TLType.Node storage n = s.nm[nodeAddress];
        require(!n.isEmpty());
        n.queue(s);
    }

    function unqueueNode(address nodeAddress) onlyRegistry public {
        TLType.Node storage n = s.nm[nodeAddress];
        require(!n.isEmpty());
        n.unqueue(s);
    }

    function displaceNode(address nodeAddress) onlyAuthorized(nodeAddress) public returns (address) {
        return s.displaceNode(nodeAddress);
    }

    function deleteNode(address nodeAddress) onlyAuthorized(nodeAddress) public {
        return s.deleteNode(nodeAddress);
    }

    function createTablespace(string calldata tsName, TiesDBRestrictions rs) external returns (bytes32) {
        return s.createTablespace(tsName, rs);
    }

    function deleteTablespace(bytes32 tsKey) external {
        s.deleteTablespace(tsKey);
    }

    function createField(bytes32 tKey,
        string calldata fName, string calldata fType, bytes calldata fDefault) external returns (bytes32) {
        return s.getTable(tKey).createField(fName, fType, fDefault);
    }

    function getStorage() public view returns (bytes32[] memory tablespaces, address[] memory nodes) {
        return s.export();
    }

    function hasTablespace(bytes32 tsKey) external view returns (bool) {
        return s.hasTablespace(tsKey);
    }

    function getTablespaceName(bytes32 tsKey) external view returns (string memory) {
        return s.tsm[tsKey].getName();
    }

    function getTablespace(bytes32 tsKey) external view returns (string memory name, address rs, bytes32[] memory tables) {
        return s.tsm[tsKey].export();
    }

    function createTable(bytes32 tsKey, string calldata tName) external returns (bytes32) {
        bytes32 tKey = s.tsm[tsKey].createTable(tName);
        s.table_to_tablespace[tKey] = tsKey;
        return tKey;
    }

    function deleteTable(bytes32 tKey) external {
        s.deleteTable(tKey);
    }

    function hasTable(bytes32 tKey) external view returns (bool) {
        return s.table_to_tablespace[tKey] != 0;
    }

    function getTableName(bytes32 tKey) external view returns (string memory) {
        return s.getTable(tKey).getName();
    }

    function getTable(bytes32 tKey) external view returns (string memory name, string memory tsName,
        bytes32[] memory fields, bytes32[] memory triggers, bytes32[] memory indexes, uint32 replicas, uint32 ranges, address[] memory nodes) {
        return s.getTable(tKey).export();
    }

    function deleteField(bytes32 tKey, bytes32 fKey) external {
        s.getTable(tKey).deleteField(fKey);
    }

    function hasField(bytes32 tKey, bytes32 fKey) external view returns (bool) {
        return s.getTable(tKey).hasField(fKey);
    }

    function getFieldName(bytes32 tKey, bytes32 fKey) external view returns (string memory) {
        return s.getTable(tKey).fm[fKey].getName();
    }

    function getField(bytes32 tKey, bytes32 fKey) external view returns (string memory name,
        string memory fType, bytes memory def) {
        return s.getTable(tKey).fm[fKey].export();
    }

    function createTrigger(bytes32 tKey,
        string calldata trName, bytes calldata payload) external returns (bytes32) {
        return s.getTable(tKey).createTrigger(trName, payload);
    }

    function deleteTrigger(bytes32 tKey, bytes32 trKey) external {
        s.getTable(tKey).deleteTrigger(trKey);
    }

    function hasTrigger(bytes32 tKey, bytes32 trKey) external view returns (bool) {
        return s.getTable(tKey).hasTrigger(trKey);
    }

    function getTriggerName(bytes32 tKey, bytes32 trKey) external view returns (string memory) {
        return s.getTable(tKey).trm[trKey].getName();
    }

    function getTrigger(bytes32 tKey, bytes32 trKey) external view returns (string memory name, bytes memory payload) {
        return s.getTable(tKey).trm[trKey].export();
    }

    function createIndex(bytes32 tKey, string calldata iName, uint8 iType, bytes32[] calldata fields) external returns (bytes32) {
        return s.getTable(tKey).createIndex(iName, iType, fields);
    }

    function deleteIndex(bytes32 tKey, bytes32 iKey) external {
        s.getTable(tKey).deleteIndex(iKey);
    }

    function hasIndex(bytes32 tKey, bytes32 iKey) external view returns (bool) {
        return s.getTable(tKey).hasIndex(iKey);
    }

    function getIndexName(bytes32 tKey, bytes32 iKey) external view returns (string memory) {
        return s.getTable(tKey).im[iKey].getName();
    }

    function getIndex(bytes32 tKey, bytes32 iKey) external view returns (string memory name, uint8 iType, bytes32[] memory fields) {
        return s.getTable(tKey).im[iKey].export();
    }

    modifier onlyRegistry() {
        require(msg.sender == registry);
        _;
    }

    modifier onlyAuthorized(address owner) {
        require(msg.sender == registry || msg.sender == owner);
        _;
    }

    function getNodes() external view returns (address[] memory) {
        return s.nmis;
    }

    function getNode(address node) external view returns (bool inQueue, bytes32[] memory tables) {
        return s.nm[node].export();
    }

    function getTableNodes(bytes32 tKey) external view returns (address[] memory) {
        return s.getTable(tKey).na;
    }

    function getNodeTableRanges(address node, bytes32 tKey) external view returns (uint64[] memory) {
        TLType.Node storage n = s.nm[node];
        return n.getRangesPack(tKey);
    }

    function tableToTablespace(bytes32 tKey) external view returns (bytes32) {
        return s.table_to_tablespace[tKey];
    }

    function distribute(bytes32 tKey, uint32 ranges, uint32 replicas) external {
        require(uint(s.getTable(tKey).getPrimaryIndex()) != 0);
        s.distributeRanges(tKey, ranges, replicas);
    }

}
