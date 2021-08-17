pragma solidity ^0.5.0;

import "./Util.sol";
import "./TLType.sol";
import "./TLNode.sol";
import "./TLTable.sol";
import "./TLTblspace.sol";


library TLStorage {

    using TiesLibString for string;
    using TiesLibString for bytes32;
    using TiesLibAddress for address;
    using TLNode for TLType.Node;
    using TLTable for TLType.Table;
    using TLTblspace for TLType.Tablespace;

    function createTablespace(TLType.Storage storage s, string memory tsName, TiesDBRestrictions rs) public returns (bytes32) {
        bytes32 tsKey = tsName.hash();
        require(!tsKey.isEmpty());

        require(!hasTablespace(s, tsKey) && !address(rs).isFree() && rs.canCreateTablespace(tsName, msg.sender));

        TLType.Tablespace storage ts = s.tsm[tsKey];
        s.tsmis.push(tsKey);
        ts.name = tsName;
        ts.idx = s.tsmis.length;
        ts.rs = rs;

        return tsKey;
    }

    function deleteTablespace(TLType.Storage storage cont, bytes32 key) public {
        bytes32[] storage arr = cont.tsmis;

        TLType.Tablespace storage item = cont.tsm[key];
        require(!item.isEmpty() && item.rs.canDeleteTablespace(item.name, msg.sender));

        assert(arr.length > 0); //If we are here then there must be item in array
        uint256 idx = item.idx - 1;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            cont.tsm[arr[idx]].idx = idx + 1;
        }

        delete arr[arr.length-1];
        arr.length--;

        delete cont.tsm[key];
    }

    /**
    * Adds new node to available nodes pool
    * Nodes should manually enter ranges distribution queue
    */
    function createNode(TLType.Storage storage s, address nodeAddress) public {
        TLType.Node storage n = s.nm[nodeAddress];
        if(n.isEmpty()){
            //Creating new node only if it was not created before
            // s.tsmis.push(keccak256('sdfas'));
            n.idx = s.nmis.push(nodeAddress);
            s.nim[nodeAddress].push(n.idx);
        }
    }

    /**
    * Deletes empty node from queue and all nodes list
    */
    function deleteNode(TLType.Storage storage s, address nodeAddress) public {
        uint[] storage nodeIds = s.nim[nodeAddress];
        TLType.Node storage n = s.nm[nodeAddress];
        require(!n.isEmpty()); //Node should exist
        for (uint i = 0; i < nodeIds.length; i++) {
            require(nodeAddress == s.nmis[nodeIds[i]-1]); //Node should exist
            require(s.trm[nodeIds[i]-1].idx.length == 0); //Node should be empty of ranges to be removed
        }

        n.unqueue(s);

        { //Delete node from array of all nodes
            address[] storage arr = s.nmis;
            assert(arr.length > 0); //If we are here then there must be table in array
            uint idx = n.idx - 1; //One based
            if (arr.length > 1 && idx != arr.length-1) {
                arr[idx] = arr[arr.length-1];
                s.nm[arr[idx]].idx = idx + 1; //One based
            }
            delete arr[arr.length-1];
            arr.length--;
        }

        delete s.nm[nodeAddress];
    }

    function queueNode(TLType.Storage storage s, address nodeAddress) public {
        TLType.Node storage n = s.nm[nodeAddress];
        require(!n.isEmpty());
        n.queue(s);
    }

    function unqueueNode(TLType.Storage storage s, address nodeAddress) public {
        TLType.Node storage item = s.nm[nodeAddress];
        require(!item.isEmpty());
        item.unqueue(s);
    }

    function distributeRange(TLType.Storage storage s, bytes32 tKey, uint32 divider, uint32 remainder) public returns (address) {
        address nodeAddress = s.queue[s.queueHead];
        s.queueHead = (s.queueHead + 1) % s.queue.length;
        s.nm[nodeAddress].distributeRange(s, tKey, divider, remainder);
        return nodeAddress;
    }

    function distributeRanges(TLType.Storage storage s, bytes32 tKey, uint32 ranges, uint32 replicas) public {
        require(s.queue.length >= replicas); //Can not distribute ranges when number of nodes is less than number of replicas

        TLType.Table storage table = getTable(s, tKey);
        require(!table.isEmpty());

        require(table.ts.rs.canDistributeRanges(table.ts.name, table.name, msg.sender));

        require(table.replicas == 0 && table.ranges == 0);
        table.replicas = replicas;
        table.ranges = ranges;
        
        for ( uint32 r=0; r < replicas; ++r ) {
            for ( uint32 d=0; d < ranges; ++d ) {
                address nodeAddress = distributeRange(s, tKey, ranges, d);
                uint[] storage nodeIds = s.nim[nodeAddress];
                tableAddNode(table, nodeIds[0]);
            }
        }
    }

    function displaceNode(TLType.Storage storage s, address nodeAddress) public returns (address) {
        TLType.Node storage n = s.nm[nodeAddress];
        require(!n.isEmpty());
        n.unqueue(s);
        address replAddress = s.queue[s.queueHead];
        TLType.Node storage r = s.nm[replAddress];
        require(!r.isEmpty());
        s.queueHead = (s.queueHead + 1) % s.queue.length;
        uint[] storage nodeIds = s.nim[nodeAddress];
        require(nodeIds.length > 0);
        for (uint i = 0; i < nodeIds.length; i++) {
            s.nmis[nodeIds[i]-1] = replAddress;
            s.nim[replAddress].push(nodeIds[i]);
        }
        n.idx = s.nmis.push(nodeAddress);
        delete s.nim[nodeAddress];
        s.nim[nodeAddress].push(n.idx);
        return replAddress;
    }

    function hasTablespace(TLType.Storage storage s, bytes32 tsKey) public view returns (bool) {
        return !s.tsm[tsKey].isEmpty();
    }

    function redistributeRange(TLType.Storage storage s, TLType.Node storage n,
        bytes32 tKey, uint32 divider, uint32 remainder) unqueueOnExecution(s, n) public {
        _redistributeRange(s, n, tKey, divider, remainder);
    }

    function redistributeTableRanges(TLType.Storage storage s, TLType.Node storage n,
        bytes32 tKey) unqueueOnExecution(s, n) public {
        _redistributeTableRanges(s, n, tKey);
    }

    function redistributeRanges(TLType.Storage storage s, TLType.Node storage n) unqueueOnExecution(s, n) public {
        _redistributeRanges(s, n.idx);
    }

    function _redistributeRange(TLType.Storage storage s, TLType.Node storage n,
        bytes32 tKey, uint32 divider, uint32 remainder) private {
        //requires n to NOT be on queue!!!
        require(n.deleteRange(s, tKey, divider, remainder));
        distributeRange(s, tKey, divider, remainder);
    }

    function _redistributeTableRanges(TLType.Storage storage s, TLType.Node storage n, bytes32 tKey) private {
        TLType.Ranges storage rs = n.getRanges(s, tKey);
        for(int i=int(rs.ranges.length)-1; i>=0; --i){
            TLType.Range storage r = rs.ranges[uint(i)];
            _redistributeRange(s, n, tKey, r.divider, r.remainder);
        }
    }

    function _redistributeRanges(TLType.Storage storage s, uint nodeId) private {
        TLType.Node storage n = s.nm[s.nmis[nodeId-1]];
        require(!n.isEmpty());
        for ( int j=int(s.trm[nodeId].idx.length) - 1; j>=0; --j){
            _redistributeTableRanges(s, n, s.trm[nodeId].idx[uint(j)]);
        }
    }

    function getTable(TLType.Storage storage s, bytes32 tKey) internal view returns (TLType.Table storage) {
        bytes32 tsKey = s.table_to_tablespace[tKey];
        require(tsKey != 0);
        TLType.Tablespace storage ts = s.tsm[tsKey];
        TLType.Table storage table = ts.tm[tKey];
        require(!table.isEmpty());
        return table;
    }

    function deleteTable(TLType.Storage storage s, bytes32 tKey) internal {
        TLType.Table storage table = getTable(s,tKey);
        uint[] storage nodeIds = table.nid;
        for( uint i=0; i<nodeIds.length; i++) {
            TLType.Node storage node = s.nm[s.nmis[nodeIds[i]-1]];
            require(!node.isEmpty());
            node.deleteTable(s, tKey);
        }
        bytes32 tsKey = s.table_to_tablespace[tKey];
        require(tsKey != 0);
        s.tsm[tsKey].deleteTable(tKey);
        delete s.table_to_tablespace[tKey];
    }

    function getTablespaceKeys(TLType.Storage storage s) internal view returns (bytes32[] memory) {
        return s.tsmis;
    }

    modifier unqueueOnExecution(TLType.Storage storage s, TLType.Node storage n) {
        bool queued = n.unqueue(s);
        _;
        if(queued) n.queue(s);
    }

    function export(TLType.Storage storage s) internal view returns (bytes32[] memory tablespaces, address[] memory nodes) {
        tablespaces = s.tsmis;
        nodes = s.nmis;
    }

    function tableAddNode(TLType.Table storage table, uint nodeId) internal {
        if(table.nidm[nodeId] == 0) {
            table.nidm[nodeId] = table.nid.push(nodeId);
        }
    }

}