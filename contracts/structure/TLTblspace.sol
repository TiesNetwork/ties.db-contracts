pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";
import "./TLTable.sol";

library TLTblspace {

    using TiesLibString for string;
    using TiesLibString for bytes32;
    using TLTable for TLType.Table;

    function createTable(TLType.Tablespace storage ts, string tName) public returns (bytes32) {
        require(!tName.hash().isEmpty());
        var tKey = keccak256(ts.name, "#", tName);

        require(!hasTable(ts, tKey) && ts.rs.canCreateTable(ts.name, tName, msg.sender));

        var t = ts.tm[tKey];
        ts.tmis.push(tKey);
        t.name = tName;
        t.ts = ts;
        t.idx = ts.tmis.length;

        return tKey;
    }

    function deleteTable(TLType.Tablespace storage cont, bytes32 key) public {
        var map = cont.tm;
        var arr = cont.tmis;

        var item = map[key];
        require(!item.isEmpty() && cont.rs.canDeleteTable(cont.name, item.name, msg.sender));

        assert(arr.length > 0); //If we are here then there must be table in array
        var idx = item.idx - 1;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            map[arr[idx]].idx = idx + 1;
        }

        delete arr[arr.length-1];
        arr.length--;

        delete map[key];
    }

    function hasTable(TLType.Tablespace storage ts, bytes32 tKey) internal view returns (bool) {
        return !ts.tm[tKey].isEmpty();
    }

    function getTablesKeys(TLType.Tablespace storage ts) internal view returns (bytes32[]) {
        require(!isEmpty(ts));
        return ts.tmis;
    }

    function getName(TLType.Tablespace storage ts) internal view returns (string) {
        require(!isEmpty(ts));
        return ts.name;
    }

    function export(TLType.Tablespace storage ts) internal view returns (string name, address rs, bytes32[] tables) {
        name = ts.name;
        rs = address(ts.rs);
        tables = ts.tmis;
    }

    function isEmpty(TLType.Tablespace storage ts) internal view returns (bool){
        return ts.idx == 0;
    }


}