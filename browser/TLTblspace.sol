pragma solidity ^0.4.15;

import "browser/Util.sol";
import "browser/TLType.sol";

library TLTblspace {

    using TiesLibString for string;

    function getTablespaceName(TLType.Tablespace storage ts) constant internal returns (string) {
        require(ts.set);
        return ts.name;
    }

    function createTable(TLType.Tablespace storage ts, string tName) public returns (bytes32) {
        var tKey = tName.hash();
        require(!hasTable(ts, tKey) && ts.rs.canCreateTable(ts.name, tName, msg.sender));
        ts.tm[tKey] = TLType.Table({set: true, name: tName, ts: ts, tmi: ts.tmis.length, fmis: new bytes32[](0)});
        ts.tmis.push(tKey);
        return tKey;
    }

    function deleteTable(TLType.Tablespace storage ts, bytes32 tKey) public {
        var t = ts.tm[tKey];
        require(t.set && ts.rs.canDeleteTable(ts.name, t.name, msg.sender));
        if(ts.tmis.length > 1){
            ts.tmis[t.tmi] = ts.tmis[ts.tmis.length-1];
        }
        ts.tmis.length--;
        delete ts.tm[tKey];
    }

    function hasTable(TLType.Tablespace storage ts, bytes32 tKey) constant public returns (bool) {
        return ts.tm[tKey].set;
    }

    function getTablesKeys(TLType.Tablespace storage ts) constant internal returns (bytes32[]) {
        require(ts.set);
        return ts.tmis;
    }
}