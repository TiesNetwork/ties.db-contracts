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