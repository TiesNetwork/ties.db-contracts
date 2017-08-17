pragma solidity ^0.4.15;

import "browser/Util.sol";
import "browser/TLType.sol";
import "browser/TLTspace.sol";

library TLStorage {

    using TiesLibString for string;
    using TiesLibAddress for address;
    using TLTspace for TLType.Tablespace;

    function createTablespace(TLType.Storage storage s, string tsName, TiesDBRestrictions rs) public returns (bytes32) {
        var tsKey = tsName.hash();
        require(!hasTablespace(s, tsKey) && rs.canCreateTablespace(tsName, msg.sender));
        s.tsm[tsName.hash()] = TLType.Tablespace({name: tsName, rs: rs, tsmi: s.tsmis.length, tmis: new bytes32[](0)});
        s.tsmis.push(tsKey);
        return tsKey;
    }

    function deleteTablespace(TLType.Storage storage s, bytes32 tsKey) public {
        var ts = s.tsm[tsKey];
        require(ts.isSet() && ts.rs.canDeleteTablespace(ts.name, msg.sender));
        if(s.tsmis.length > 1){
            s.tsmis[ts.tsmi] = s.tsmis[s.tsmis.length-1];
        }
        s.tsmis.length--;
    }

    function hasTablespace(TLType.Storage storage s, bytes32 tsKey) constant public returns (bool) {
        return s.tsm[tsKey].isSet();
    }

    function getTablespaceKeys(TLType.Storage storage s) constant internal returns (bytes32[]) {
        return s.tsmis;
    }
}