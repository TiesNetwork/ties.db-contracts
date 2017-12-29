pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";


library TLTable {

    using TiesLibString for string;

    function createField(TLType.Table storage t, string fName,
            string fType, bytes fDefault) public returns (bytes32) {
        var fKey = fName.hash();
        require(!hasField(t, fKey) && t.ts.rs.canCreateField(t.ts.name, t.name, fName, msg.sender));
        t.fm[fKey] = TLType.Field({name: fName, t: t, idx: t.fmis.length, fType: fType, fDefault: fDefault});
        t.fmis.push(fKey);
        return fKey;
    }

    function deleteField(TLType.Table storage cont, bytes32 key) public {
        var map = cont.fm;
        var arr = cont.fmis;

        var item = map[key];
        require(!item.name.isEmpty() && cont.ts.rs.canDeleteTrigger(cont.ts.name, cont.name, item.name, msg.sender));

        assert(arr.length > 0); //If we are here then there must be table in array
        var idx = cont.idx;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            map[arr[idx]].idx = idx;
        }

        delete arr[arr.length-1];
        arr.length--;

        delete map[key];
    }

    function createTrigger(TLType.Table storage t, string trName, bytes payload) public returns (bytes32) {
        var trKey = trName.hash();
        require(!hasTrigger(t, trKey) && t.ts.rs.canCreateTrigger(t.ts.name, t.name, trName, msg.sender));
        t.trm[trKey] = TLType.Trigger({name: trName, t: t, idx: t.trmis.length, payload: payload});
        t.trmis.push(trKey);
        return trKey;
    }

    function hasField(TLType.Table storage t, bytes32 fKey) public constant returns (bool) {
        return !t.fm[fKey].name.isEmpty();
    }

    function deleteTrigger(TLType.Table storage cont, bytes32 key) public {
        var map = cont.trm;
        var arr = cont.trmis;

        var item = map[key];
        require(!item.name.isEmpty() && cont.ts.rs.canDeleteTrigger(cont.ts.name, cont.name, item.name, msg.sender));

        assert(arr.length > 0); //If we are here then there must be table in array
        var idx = cont.idx;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            map[arr[idx]].idx = idx;
        }

        delete arr[arr.length-1];
        arr.length--;

        delete map[key];
    }

    function hasTrigger(TLType.Table storage t, bytes32 trKey) public constant returns (bool) {
        return !t.trm[trKey].name.isEmpty();
    }

    function getFieldsKeys(TLType.Table storage t) internal constant returns (bytes32[]) {
        require(!t.name.isEmpty());
        return t.fmis;
    }

    function getTableName(TLType.Table storage t) internal constant returns (string) {
        require(!t.name.isEmpty());
        return t.name;
    }

    function getTriggersKeys(TLType.Table storage t) internal constant returns (bytes32[]) {
        require(!t.name.isEmpty());
        return t.trmis;
    }

}