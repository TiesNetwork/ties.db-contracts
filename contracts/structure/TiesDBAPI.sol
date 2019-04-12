pragma solidity ^0.5.0;

interface TiesDBRestrictions {
    function canCreateTablespace(string calldata tsName, address owner) external  view returns (bool);
    function canDeleteTablespace(string calldata tsName, address owner) external view returns (bool);

    function canCreateTable(string calldata tsName, string calldata tName, address owner) external view returns (bool);
    function canDeleteTable(string calldata tsName, string calldata tName, address owner) external view returns (bool);
    function canDistributeRanges(string calldata tsName, string calldata tName, address owner) external view returns (bool);

    function canCreateField(string calldata tsName, string calldata tName, string calldata fName, address owner) external view returns (bool);
    function canDeleteField(string calldata tsName, string calldata tName, string calldata fName, address owner) external view returns (bool);

    function canCreateTrigger(string calldata tsName, string calldata tName, string calldata fName, address owner) external view returns (bool);
    function canDeleteTrigger(string calldata tsName, string calldata tName, string calldata fName, address owner) external view returns (bool);

    function canCreateIndex(string calldata tsName, string calldata tName, string calldata iName, address owner) external view returns (bool);
    function canDeleteIndex(string calldata tsName, string calldata tName, string calldata iName, address owner) external view returns (bool);
}

interface TiesDBNodes {
    function createNode(address _node) external;
    function queueNode(address _node) external;
    function unqueueNode(address _node) external;
}

interface TiesDBSchema {
    function createTablespace(string calldata tsName, TiesDBRestrictions rs) external returns (bytes32);
    function deleteTablespace(bytes32 tsKey) external;
    function hasTablespace(bytes32 tsKey) external view returns (bool);
    function getTablespaceName(bytes32 tsKey) external view returns (string memory);
    function getTablespace(bytes32 tsKey) external view returns (string memory name, address rs, bytes32[] memory tables);

    function createTable(bytes32 tsKey, string calldata tName) external returns (bytes32);
    function deleteTable(bytes32 tKey) external;
    function hasTable(bytes32 tKey) external view returns (bool);
    function getTableName(bytes32 tKey) external view returns (string memory);
    function getTable(bytes32 tKey) external view returns (string memory name, string memory tsName, bytes32[] memory fields, bytes32[] memory triggers, bytes32[] memory indexes, uint32 replicas, uint32 ranges, address[] memory nodes);

    function createField(bytes32 tKey, string calldata fName, string calldata fType, bytes calldata fDefault) external returns (bytes32);
    function deleteField(bytes32 tKey, bytes32 fKey) external;
    function hasField(bytes32 tKey, bytes32 fKey) external view returns (bool);
    function getFieldName(bytes32 tKey, bytes32 fKey) external view returns (string memory);
    function getField(bytes32 tKey, bytes32 fKey) external view returns (string memory name, string memory fType, bytes memory def);

    function createTrigger(bytes32 tKey, string calldata trName, bytes calldata payload) external returns (bytes32);
    function deleteTrigger(bytes32 tKey, bytes32 trKey) external;
    function hasTrigger(bytes32 tKey, bytes32 trKey) external view returns (bool);
    function getTriggerName(bytes32 tKey, bytes32 trKey) external view returns (string memory);
    function getTrigger(bytes32 tKey, bytes32 trKey) external view returns (string memory name, bytes memory payload);

    function createIndex(bytes32 tKey, string calldata iName, uint8 iType, bytes32[] calldata fields) external returns (bytes32);
    function deleteIndex(bytes32 tKey, bytes32 iKey) external;
    function hasIndex(bytes32 tKey, bytes32 iKey) external view returns (bool);
    function getIndexName(bytes32 tKey, bytes32 iKey) external view returns (string memory);
    function getIndex(bytes32 tKey, bytes32 iKey) external view returns (string memory name, uint8 iType, bytes32[] memory fields);

    function getNodes() external view returns (address[] memory);
    function getNode(address node) external view returns (bool inQueue, bytes32[] memory tables);
    function getTableNodes(bytes32 tKey) external view returns (address[] memory);
    function getNodeTableRanges(address node, bytes32 tKey) external view returns (uint64[] memory);

    function tableToTablespace(bytes32 tKey) external view returns (bytes32);
    function distribute(bytes32 tKey, uint32 ranges, uint32 replicas) external;
}