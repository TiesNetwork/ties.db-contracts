pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";


library TLTable {

    using TiesLibString for string;

    function createField(TLType.Table storage t, string fName,
            string fType, bytes fDefault) public returns (bytes32) {
        var fKey = fName.hash();
        require(!hasField(t, fKey) && t.ts.rs.canCreateField(t.ts.name, t.name, fName, msg.sender));
        t.fm[fKey] = TLType.Field({name: fName, t: t, fmi: t.fmis.length, fType: fType, fDefault: fDefault});
        t.fmis.push(fKey);
        return fKey;
    }

    function deleteField(TLType.Table storage t, bytes32 fKey) public {
        var f = t.fm[fKey];
        require(!f.name.isEmpty() && t.ts.rs.canDeleteField(t.ts.name, t.name, f.name, msg.sender));

        var idx = f.fmi;
        if (t.fmis.length > 1 && idx != t.fmis.length-1) {
            t.fmis[idx] = t.fmis[t.fmis.length-1];
            t.fm[t.fmis[idx]].fmi = idx;
        }

        delete t.fmis[t.fmis.length-1];
        t.fmis.length--;

        delete t.fm[fKey];
    }

    function createTrigger(TLType.Table storage t, string trName, bytes payload) public returns (bytes32) {
        var trKey = trName.hash();
        require(!hasTrigger(t, trKey) && t.ts.rs.canCreateTrigger(t.ts.name, t.name, trName, msg.sender));
        t.trm[trKey] = TLType.Trigger({name: trName, t: t, trmi: t.trmis.length, payload: payload});
        t.trmis.push(trKey);
        return trKey;
    }

    function hasField(TLType.Table storage t, bytes32 fKey) public constant returns (bool) {
        return !t.fm[fKey].name.isEmpty();
    }

    function deleteTrigger(TLType.Table storage t, bytes32 trKey) public {
        var tr = t.trm[trKey];
        require(!tr.name.isEmpty() && t.ts.rs.canDeleteTrigger(t.ts.name, t.name, tr.name, msg.sender));

        var idx = tr.trmi;
        if (t.trmis.length > 1 && idx != t.trmis.length-1) {
            t.trmis[idx] = t.trmis[t.trmis.length-1];
            t.trm[t.trmis[idx]].trmi = idx;
        }

        delete t.trmis[t.trmis.length-1];
        t.trmis.length--;

        delete t.trm[trKey];
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