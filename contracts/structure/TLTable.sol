pragma solidity ^0.5.0;

import "./Util.sol";
import "./TLType.sol";
import "./TLField.sol";
import "./TLTrigger.sol";
import "./TLIndex.sol";


library TLTable {

    using TiesLibString for string;
    using TiesLibString for bytes32;
    using TLField for TLType.Field;
    using TLTrigger for TLType.Trigger;
    using TLIndex for TLType.Index;

    function createField(TLType.Table storage t, string memory fName,
            string memory fType, bytes memory fDefault) public returns (bytes32) {

        bytes32 fKey = fName.hash();
        require(!fKey.isEmpty());
        require(!hasField(t, fKey) && t.ts.rs.canCreateField(t.ts.name, t.name, fName, msg.sender));
        t.fmis.push(fKey);

        TLType.Field storage f = t.fm[fKey];
        f.idx = t.fmis.length;
        f.name = fName;
        f.fType = fType;
        f.fDefault = fDefault;

        return fKey;
    }

    function deleteField(TLType.Table storage cont, bytes32 key) public {
        bytes32[] storage arr = cont.fmis;

        TLType.Field storage item = cont.fm[key];
        require(!item.isEmpty() && cont.ts.rs.canDeleteTrigger(cont.ts.name, cont.name, item.name, msg.sender));

        assert(arr.length > 0); //If we are here then there must be table in array
        uint256 idx = item.idx - 1;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            cont.fm[arr[idx]].idx = idx + 1;
        }

        delete arr[arr.length-1];
        arr.length--;

        delete cont.fm[key];
    }

    function createTrigger(TLType.Table storage t, string memory trName, bytes memory payload) public returns (bytes32) {
        bytes32 trKey = trName.hash();
        require(!trKey.isEmpty());
        require(!hasTrigger(t, trKey) && t.ts.rs.canCreateTrigger(t.ts.name, t.name, trName, msg.sender));

        t.trmis.push(trKey);

        TLType.Trigger storage tr = t.trm[trKey];
        tr.name = trName;
        tr.idx = t.trmis.length;
        tr.payload = payload;

        return trKey;
    }

    function hasField(TLType.Table storage t, bytes32 fKey) public view returns (bool) {
        return !t.fm[fKey].isEmpty();
    }

    function deleteTrigger(TLType.Table storage cont, bytes32 key) public {
        bytes32[] storage arr = cont.trmis;

        TLType.Trigger storage item = cont.trm[key];
        require(!item.isEmpty() && cont.ts.rs.canDeleteTrigger(cont.ts.name, cont.name, item.name, msg.sender));

        assert(arr.length > 0); //If we are here then there must be table in array
        uint256 idx = item.idx - 1;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            cont.trm[arr[idx]].idx = idx + 1;
        }

        delete arr[arr.length-1];
        arr.length--;

        delete cont.trm[key];
    }

    function hasTrigger(TLType.Table storage t, bytes32 trKey) public view returns (bool) {
        return !t.trm[trKey].isEmpty();
    }

    function createIndex(TLType.Table storage t, string memory iName, uint8 iType, bytes32[] memory fields) public returns (bytes32) {
        require(iType == 1 || iType == 2 || iType == 4);
        require(fields.length > 0);
        for(uint i=0; i<fields.length; ++i){
            require(hasField(t, fields[i])); //We should have all the fields in the table
        }
        require(iType != 1 || getPrimaryIndex(t) == 0); //We can not create second primary index

        bytes32 iKey = iName.hash();
        require(!iKey.isEmpty());
        require(!hasIndex(t, iKey) && t.ts.rs.canCreateIndex(t.ts.name, t.name, iName, msg.sender));

        TLType.Index storage index = t.im[iKey];
        t.imis.push(iKey);

        index.idx = uint128(t.imis.length);
        index.iType = iType;
        index.name = iName;
        index.fields = fields;

        return iKey;
    }

    function deleteIndex(TLType.Table storage cont, bytes32 key) public {
        bytes32[] storage arr = cont.imis;

        TLType.Index storage item = cont.im[key];
        require(!item.isEmpty() && cont.ts.rs.canDeleteIndex(cont.ts.name, cont.name, item.name, msg.sender));
        require(item.iType != 1); //We can not delete primary index

        assert(arr.length > 0); //If we are here then there must be table in array
        uint256 idx = cont.idx - 1;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            cont.im[arr[idx]].idx = uint128(idx) + 1;
        }

        delete arr[arr.length-1];
        arr.length--;

        delete cont.im[key];
    }

    function hasIndex(TLType.Table storage t, bytes32 iKey) internal view returns (bool) {
        return !t.im[iKey].isEmpty();
    }

    function getName(TLType.Table storage t) internal view returns (string memory) {
        require(!isEmpty(t));
        return t.name;
    }

    function export(TLType.Table storage t) internal view returns (string memory name, string memory tsName,
        bytes32[] memory fields, bytes32[] memory triggers, bytes32[] memory indexes, uint32 replicas, uint32 ranges, address[] memory nodes) {
        name = t.name;
        tsName = t.ts.name;
        fields = t.fmis;
        triggers = t.trmis;
        indexes = t.imis;
        replicas = t.replicas;
        ranges = t.ranges;
        nodes = t.na;
    }

    function getPrimaryIndex(TLType.Table storage t) public view returns (bytes32){
        for(uint i=0; i<t.imis.length; ++i){
            TLType.Index storage index = t.im[t.imis[i]];
            if(index.iType == 1)
                return t.imis[i];
        }
        return 0;
    }

    function isEmpty(TLType.Table storage t) internal view returns (bool) {
        return t.idx == 0;
    }

}