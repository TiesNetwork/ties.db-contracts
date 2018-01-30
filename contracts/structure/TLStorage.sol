pragma solidity ^0.4.15;

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

    function createTablespace(TLType.Storage storage s, string tsName, TiesDBRestrictions rs) public returns (bytes32) {
        var tsKey = tsName.hash();
        require(!tsKey.isEmpty());

        require(!hasTablespace(s, tsKey) && !address(rs).isFree() && rs.canCreateTablespace(tsName, msg.sender));

        var ts = s.tsm[tsKey];
        s.tsmis.push(tsKey);
        ts.name = tsName;
        ts.idx = s.tsmis.length;
        ts.rs = rs;

        return tsKey;
    }

    function deleteTablespace(TLType.Storage storage cont, bytes32 key) public {
        var map = cont.tsm;
        var arr = cont.tsmis;

        var item = map[key];
        require(!item.isEmpty() && item.rs.canDeleteTablespace(item.name, msg.sender));

        assert(arr.length > 0); //If we are here then there must be item in array
        var idx = item.idx - 1;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            map[arr[idx]].idx = idx + 1;
        }

        delete arr[arr.length-1];
        arr.length--;

        delete map[key];
    }

    /**
    * Adds new node to available nodes pool
    * Nodes should manually enter ranges distribution queue
    */
    function createNode(TLType.Storage storage s, address node) public {
        var n = s.nm[node];
        if(n.isEmpty()){
            //Creating new node only if it was not created before
//            s.tsmis.push(keccak256('sdfas'));
            s.nmis.push(node);
            n.idx = uint128(s.nmis.length);
        }
    }

    /**
    * Deletes empty node from queue and all nodes list
    */
    function deleteNode(TLType.Storage storage s, address node) public {
        var map = s.nm;
        var item = map[node];
        require(item.idx > 0); //Node should exist
        require(item.tmis.length == 0); //Node should be empty of ranges to be removed

        { //Delete node from array of all nodes
            var arr = s.nmis;
            assert(arr.length > 0); //If we are here then there must be table in array
            var idx = item.idx - 1; //One based
            if (arr.length > 1 && idx != arr.length-1) {
                arr[idx] = arr[arr.length-1];
                map[arr[idx]].idx = idx + 1; //One based
            }
            delete arr[arr.length-1];
            arr.length--;
        }

        item.unqueue(s);

        delete map[node];
    }

    function queueNode(TLType.Storage storage s, address node) public {
        var item = s.nm[node];
        require(!item.isEmpty());
        item.queue(s);
    }

    function unqueueNode(TLType.Storage storage s, address node) public {
        var item = s.nm[node];
        require(!item.isEmpty());
        item.unqueue(s);
    }

    function distributeRange(TLType.Storage storage s, bytes32 tKey, uint32 divider, uint32 remainder) public {
        address node = s.queue[s.queue_head];
        s.queue_head = uint128((s.queue_head+1) % s.queue.length);
        s.nm[node].distributeRange(tKey, divider, remainder);
    }

    function distributeRanges(TLType.Storage storage s, bytes32 tKey, uint32 ranges, uint32 replicas) public {
        require(s.queue.length >= replicas); //Can not distribute ranges when number of nodes is less than number of replicas

        var table = getTable(s, tKey);
        require(!table.isEmpty());

        require(table.ts.rs.canDistributeRanges(table.ts.name, table.name, msg.sender));

        require(table.replicas == 0 && table.ranges == 0);
        table.replicas = replicas;
        table.ranges = ranges;

        for ( uint r=0; r < replicas; ++r ) {
            for ( uint32 d=0; d < ranges; ++d ) {
                distributeRange(s, tKey, ranges, d);
            }
        }
    }

    function hasTablespace(TLType.Storage storage s, bytes32 tsKey) public constant returns (bool) {
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
        _redistributeRanges(s, n);
    }

    function _redistributeRange(TLType.Storage storage s, TLType.Node storage n,
        bytes32 tKey, uint32 divider, uint32 remainder) private {
        //requires n to NOT be on queue!!!
        require(n.deleteRange(tKey, divider, remainder));
        distributeRange(s, tKey, divider, remainder);
    }

    function _redistributeTableRanges(TLType.Storage storage s, TLType.Node storage n, bytes32 tKey) private {
        var rs = n.getRanges(tKey);
        for(int i=int(rs.ranges.length)-1; i>=0; --i){
            var r = rs.ranges[uint(i)];
            _redistributeRange(s, n, tKey, r.divider, r.remainder);
        }
    }

    function _redistributeRanges(TLType.Storage storage s, TLType.Node storage n) private {
        for ( int j=int(n.tmis.length) - 1; j>=0; --j){
            _redistributeTableRanges(s, n, n.tmis[uint(j)]);
        }
    }

    function getTable(TLType.Storage storage s, bytes32 tKey) internal view returns (TLType.Table storage) {
        var tsKey = s.table_to_tablespace[tKey];
        var ts = s.tsm[tsKey];
        var table = ts.tm[tKey];
        require(!table.isEmpty());
        return table;
    }

    function getTablespaceKeys(TLType.Storage storage s) internal view returns (bytes32[]) {
        return s.tsmis;
    }

    modifier unqueueOnExecution(TLType.Storage storage s, TLType.Node storage n){
        bool queued = n.unqueue(s);
        _;
        if(queued) n.queue(s);
    }

    function export(TLType.Storage storage s) internal view returns (bytes32[] tablespaces, address[] nodes) {
        tablespaces = s.tsmis;
        nodes = s.nmis;
    }

}