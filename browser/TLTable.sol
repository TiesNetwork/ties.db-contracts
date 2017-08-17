pragma solidity ^0.4.15;

import "browser/Util.sol";
import "browser/TLType.sol";

library TLTable {

    using TiesLibString for string;

    function getTableName(TLType.Table storage t) constant internal returns (string) {
        require(t.set);
        return t.name;
    }

    function createField(TLType.Table storage t, string fName) public returns (bytes32) {
        var fKey = fName.hash();
        require(!hasField(t, fKey) && t.ts.rs.canCreateField(t.ts.name, t.name, fName, msg.sender));
        t.fm[fKey] = TLType.Field({set: true, name: fName, t: t, fmi: t.fmis.length});
        t.fmis.push(fKey);
        return fKey;
    }

    function deleteField(TLType.Table storage t, bytes32 fKey) public {
        var f = t.fm[fKey];
        require(f.set && t.ts.rs.canDeleteField(t.ts.name, t.name, f.name, msg.sender));
        if(t.fmis.length > 1){
            t.fmis[f.fmi] = t.fmis[t.fmis.length-1];
        }
        t.fmis.length--;
        delete t.fm[fKey];
    }

    function hasField(TLType.Table storage t, bytes32 fKey) constant public returns (bool) {
        return t.fm[fKey].set;
    }

    function getFieldsKeys(TLType.Table storage t) constant internal returns (bytes32[]) {
        require(t.set);
        return t.fmis;
    }
}