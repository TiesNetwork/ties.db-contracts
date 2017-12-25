pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";


library TLStorage {

    using TiesLibString for string;
    using TiesLibAddress for address;

    function createTablespace(TLType.Storage storage s, string tsName, TiesDBRestrictions rs) public returns (bytes32) {
        require(!tsName.isEmpty());
        var tsKey = tsName.hash();
        require(!hasTablespace(s, tsKey) && !address(rs).isFree() && rs.canCreateTablespace(tsName, msg.sender));
        s.tsm[tsKey] = TLType.Tablespace({name: tsName, rs: rs, tsmi: s.tsmis.length, tmis: new bytes32[](0)});
        s.tsmis.push(tsKey);
        return tsKey;
    }

    function deleteTablespace(TLType.Storage storage s, bytes32 tsKey) public {
        var ts = s.tsm[tsKey];
        require(!ts.name.isEmpty() && ts.rs.canDeleteTablespace(ts.name, msg.sender));
        assert(s.tsmis.length > 0); //If we have found key, it must be in array!

        var idx = ts.tsmi;
        if (s.tsmis.length > 1 && idx != s.tsmis.length - 1) {
            s.tsmis[idx] = s.tsmis[s.tsmis.length-1];
            s.tsm[s.tsmis[idx]].tsmi = idx; //Need to replace the index of the last element
        }

        delete s.tsmis[s.tsmis.length-1];
        s.tsmis.length--;

        delete s.tsm[tsKey];
    }

    function hasTablespace(TLType.Storage storage s, bytes32 tsKey) public constant returns (bool) {
        return !s.tsm[tsKey].name.isEmpty();
    }

    function getTablespaceKeys(TLType.Storage storage s) internal constant returns (bytes32[]) {
        return s.tsmis;
    }
}