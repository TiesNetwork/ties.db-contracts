pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";
import "./TLField.sol";
import "./TLTrigger.sol";
import "./TLIndex.sol";


library TLTable {

    using TiesLibString for string;
    using TLField for TLType.Field;
    using TLTrigger for TLType.Trigger;
    using TLIndex for TLType.Index;

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
        require(!item.isEmpty() && cont.ts.rs.canDeleteTrigger(cont.ts.name, cont.name, item.name, msg.sender));

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

    function hasField(TLType.Table storage t, bytes32 fKey) public view returns (bool) {
        return !t.fm[fKey].isEmpty();
    }

    function deleteTrigger(TLType.Table storage cont, bytes32 key) public {
        var map = cont.trm;
        var arr = cont.trmis;

        var item = map[key];
        require(!item.isEmpty() && cont.ts.rs.canDeleteTrigger(cont.ts.name, cont.name, item.name, msg.sender));

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

    function hasTrigger(TLType.Table storage t, bytes32 trKey) public view returns (bool) {
        return !t.trm[trKey].isEmpty();
    }

    function createIndex(TLType.Table storage t, string iName, uint8 iType, bytes32[] fields) public returns (bytes32) {
        require(iType == 1 || iType == 2 || iType == 4);
        require(fields.length > 0);
        for(uint i=0; i<fields.length; ++i){
            require(hasField(t, fields[i])); //We should have all the fields in the table
        }
        require(iType != 1 || getPrimaryIndex(t) == 0); //We can not create second primary index

        var iKey = iName.hash();
        require(!hasIndex(t, iKey) && t.ts.rs.canCreateIndex(t.ts.name, t.name, iName, msg.sender));

        var index = t.im[iKey];

        index.idx = uint128(t.imis.length);
        index.iType = iType;
        index.name = iName;
        index.fields = fields;

        t.imis.push(iKey);
        return iKey;
    }

    function deleteIndex(TLType.Table storage cont, bytes32 key) public {
        var map = cont.im;
        var arr = cont.imis;

        var item = map[key];
        require(!item.isEmpty() && cont.ts.rs.canDeleteIndex(cont.ts.name, cont.name, item.name, msg.sender));
        require(item.iType != 1); //We can not delete primary index

        assert(arr.length > 0); //If we are here then there must be table in array
        var idx = cont.idx;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            map[arr[idx]].idx = uint128(idx);
        }

        delete arr[arr.length-1];
        arr.length--;

        delete map[key];
    }

    function hasIndex(TLType.Table storage t, bytes32 iKey) public view returns (bool) {
        return !t.im[iKey].isEmpty();
    }

    function getName(TLType.Table storage t) internal view returns (string) {
        require(!isEmpty(t));
        return t.name;
    }

    function export(TLType.Table storage t) internal view returns (string name, string tsName,
        bytes32[] fields, bytes32[] triggers, bytes32[] indexes, uint32 replicas, uint32 ranges, address[] nodes) {
        name = t.name;
        tsName = t.ts.name;
        fields = t.fmis;
        triggers = t.trmis;
        indexes = t.imis;
        replicas = t.replicas;
        ranges = t.ranges;
        nodes = t.nodes;
    }

    function getPrimaryIndex(TLType.Table storage t) public view returns (bytes32){
        for(uint i=0; i<t.imis.length; ++i){
            var index = t.im[t.imis[i]];
            if(index.iType == 1)
                return t.imis[i];
        }
        return 0;
    }

    function isEmpty(TLType.Table storage t) internal view returns (bool) {
        return t.name.isEmpty();
    }

}