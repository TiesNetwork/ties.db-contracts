pragma solidity ^0.4.15;

import "browser/Util.sol";
import "browser/TLType.sol";
import "browser/TLField.sol";

library TLTable {

    using TiesLibString for string;
    using TiesLibAddress for address;
    using TLField for TLType.Field;

    function isSet(TLType.Table storage t) constant public returns (bool) {
        return !address(t.ts.rs).isFree();
    }

    function getTableName(TLType.Table storage t) constant internal returns (string) {
        require(isSet(t));
        return t.name;
    }

    function getTableFieldsKeys(TLType.Table storage t) constant internal returns (bytes32[]) {
        require(isSet(t));
        return t.fmis;
    }

    function createField(TLType.Table storage t, string fName) public returns (bytes32) {
        var fKey = fName.hash();
        require(!hasField(t, fKey) && t.ts.rs.canCreateField(t.ts.name, t.name, fName, msg.sender));
        t.fm[fKey] = TLType.Field({name: fName, t: t, fmi: t.fmis.length});
        t.fmis.push(fKey);
        return fKey;
    }

    function deleteField(TLType.Table storage t, bytes32 fKey) public {
        var f = t.fm[fKey];
        require(f.isSet() && t.ts.rs.canDeleteField(t.ts.name, t.name, f.name, msg.sender));
        if(t.fmis.length > 1){
            t.fmis[f.fmi] = t.fmis[t.fmis.length-1];
        }
        t.fmis.length--;
    }

    function hasField(TLType.Table storage t, bytes32 fKey) constant public returns (bool) {
        return t.fm[fKey].isSet();
    }
}