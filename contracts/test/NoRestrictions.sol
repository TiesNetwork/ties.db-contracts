pragma solidity ^0.5.0;

import "..//structure/TiesDBAPI.sol";

contract NoRestrictions is TiesDBRestrictions {
    function canCreateTablespace(string calldata, address) external view returns (bool) { return true; }
    function canDeleteTablespace(string calldata, address) external view returns (bool) { return true; }

    function canCreateTable(string calldata, string calldata, address) external view returns (bool) { return true; }
    function canDeleteTable(string calldata, string calldata, address) external view returns (bool) { return true; }
    function canDistributeRanges(string calldata, string calldata, address) external view returns (bool) { return true; }

    function canCreateField(string calldata, string calldata, string calldata, address) external view returns (bool) { return true; }
    function canDeleteField(string calldata, string calldata, string calldata, address) external view returns (bool) { return true; }

    function canCreateTrigger(string calldata, string calldata, string calldata, address) external view returns (bool) { return true; }
    function canDeleteTrigger(string calldata, string calldata, string calldata, address) external view returns (bool) { return true; }

    function canCreateIndex(string calldata, string calldata, string calldata, address) external view returns (bool) {
        return true;
    }

    function canDeleteIndex(string calldata, string calldata, string calldata, address) external view returns (bool) {
        return true;
    }
}
