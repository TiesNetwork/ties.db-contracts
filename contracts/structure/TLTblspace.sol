pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";


library TLTblspace {

    using TiesLibString for string;

    function createTable(TLType.Tablespace storage ts, string tName) public returns (bytes32) {
        require(!tName.isEmpty());
        var tKey = keccak256(ts.name, "#", tName);
        require(!hasTable(ts, tKey) && ts.rs.canCreateTable(ts.name, tName, msg.sender));

        var t = ts.tm[tKey];
        t.name = tName;
        t.ts = ts;
        t.idx = ts.tmis.length;

        ts.tmis.push(tKey);

        return tKey;
    }

    function deleteTable(TLType.Tablespace storage cont, bytes32 key) public {
        var map = cont.tm;
        var arr = cont.tmis;

        var item = map[key];
        require(!item.name.isEmpty() && cont.rs.canDeleteTable(cont.name, item.name, msg.sender));

        assert(arr.length > 0); //If we are here then there must be table in array
        var idx = item.idx;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            map[arr[idx]].idx = idx;
        }

        delete arr[arr.length-1];
        arr.length--;

        delete map[key];
    }


    function hasTable(TLType.Tablespace storage ts, bytes32 tKey) public view returns (bool) {
        return !ts.tm[tKey].name.isEmpty();
    }

    function getTablesKeys(TLType.Tablespace storage ts) internal view returns (bytes32[]) {
        require(!ts.name.isEmpty());
        return ts.tmis;
    }

    function getName(TLType.Tablespace storage ts) internal view returns (string) {
        require(!ts.name.isEmpty());
        return ts.name;
    }

    function export(TLType.Tablespace storage ts) internal view returns (string name, address rs, bytes32[] tables) {
        name = ts.name;
        rs = address(ts.rs);
        tables = ts.tmis;
    }


}