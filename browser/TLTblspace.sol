pragma solidity ^0.4.15;

import "browser/Util.sol";
import "browser/TLType.sol";
import "browser/TLTable.sol";

library TLTspace {

    using TiesLibString for string;
    using TiesLibAddress for address;
    using TLTable for TLType.Table;

    function isSet(TLType.Tablespace storage ts) constant public returns (bool) {
        return !address(ts.rs).isFree();
    }
    
    function getTablespaceName(TLType.Tablespace storage ts) constant internal returns (string) {
        require(isSet(ts));
        return ts.name;
    }

    function getTablespaceTablesKeys(TLType.Tablespace storage ts) constant internal returns (bytes32[]) {
        require(isSet(ts));
        return ts.tmis;
    }

    function createTable(TLType.Tablespace storage ts, string tName) public returns (bytes32) {
        var tKey = tName.hash();
        require(!hasTable(ts, tKey) && ts.rs.canCreateTable(ts.name, tName, msg.sender));
        ts.tm[tKey] = TLType.Table({name: tName, ts: ts, tmi: ts.tmis.length, fmis: new bytes32[](0)});
        ts.tmis.push(tKey);
        return tKey;
    }

    function deleteTable(TLType.Tablespace storage ts, bytes32 tKey) public {
        var t = ts.tm[tKey];
        require(t.isSet() && ts.rs.canDeleteTable(ts.name, t.name, msg.sender));
        if(ts.tmis.length > 1){
            ts.tmis[t.tmi] = ts.tmis[ts.tmis.length-1];
        }
        ts.tmis.length--;
    }

    function hasTable(TLType.Tablespace storage ts, bytes32 tKey) constant public returns (bool) {
        return ts.tm[tKey].isSet();
    }
}