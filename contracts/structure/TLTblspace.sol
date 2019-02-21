pragma solidity ^0.5.0;

import "./Util.sol";
import "./TLType.sol";
import "./TLTable.sol";

library TLTblspace {

    using TiesLibString for string;
    using TiesLibString for bytes32;
    using TLTable for TLType.Table;

    function createTable(TLType.Tablespace storage ts, string memory tName) public returns (bytes32) {
        require(!tName.hash().isEmpty());
        bytes32 tKey = keccak256(abi.encodePacked(ts.name, "#", tName));

        require(!hasTable(ts, tKey) && ts.rs.canCreateTable(ts.name, tName, msg.sender));

        TLType.Table storage t = ts.tm[tKey];
        ts.tmis.push(tKey);
        t.name = tName;
        t.ts = ts;
        t.idx = ts.tmis.length;

        return tKey;
    }

    function deleteTable(TLType.Tablespace storage cont, bytes32 key) public {
        bytes32[] storage arr = cont.tmis;

        TLType.Table storage item = cont.tm[key];
        require(!item.isEmpty() && cont.rs.canDeleteTable(cont.name, item.name, msg.sender));

        assert(arr.length > 0); //If we are here then there must be table in array
        uint256 idx = item.idx - 1;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            cont.tm[arr[idx]].idx = idx + 1;
        }

        delete arr[arr.length-1];
        arr.length--;

        delete cont.tm[key];
    }

    function hasTable(TLType.Tablespace storage ts, bytes32 tKey) internal view returns (bool) {
        return !ts.tm[tKey].isEmpty();
    }

    function getTablesKeys(TLType.Tablespace storage ts) internal view returns (bytes32[] memory) {
        require(!isEmpty(ts));
        return ts.tmis;
    }

    function getName(TLType.Tablespace storage ts) internal view returns (string memory) {
        require(!isEmpty(ts));
        return ts.name;
    }

    function export(TLType.Tablespace storage ts) internal view returns (string memory name, address rs, bytes32[] memory tables) {
        name = ts.name;
        rs = address(ts.rs);
        tables = ts.tmis;
    }

    function isEmpty(TLType.Tablespace storage ts) internal view returns (bool){
        return ts.idx == 0;
    }


}