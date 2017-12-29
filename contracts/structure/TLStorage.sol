pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";
import "./TLNode.sol";


library TLStorage {

    using TiesLibString for string;
    using TiesLibAddress for address;
    using TLNode for TLType.Node;

    function createTablespace(TLType.Storage storage s, string tsName, TiesDBRestrictions rs) public returns (bytes32) {
        require(!tsName.isEmpty());
        var tsKey = tsName.hash();
        require(!hasTablespace(s, tsKey) && !address(rs).isFree() && rs.canCreateTablespace(tsName, msg.sender));
        s.tsm[tsKey] = TLType.Tablespace({name: tsName, rs: rs, idx: s.tsmis.length, tmis: new bytes32[](0)});
        s.tsmis.push(tsKey);
        return tsKey;
    }

    function deleteTablespace(TLType.Storage storage cont, bytes32 key) public {
        var map = cont.tsm;
        var arr = cont.tsmis;

        var item = map[key];
        require(!item.name.isEmpty() && item.rs.canDeleteTablespace(item.name, msg.sender));

        assert(arr.length > 0); //If we are here then there must be table in array
        var idx = item.idx;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            map[arr[idx]].idx = idx;
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
        require(!s.nm[node].isEmpty()); //There is still no active node with this address

        s.nm[node] = TLType.Node({idx: uint128(s.nmis.length), queue_idx: 0, tmis: new bytes32[](0)});
        s.nmis.push(node);
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
        for ( uint r=0; r < replicas; ++r ) {
            for ( uint32 d=0; d < ranges; ++d ) {
                distributeRange(s, tKey, ranges, d);
            }
        }
    }

    function hasTablespace(TLType.Storage storage s, bytes32 tsKey) public constant returns (bool) {
        return !s.tsm[tsKey].name.isEmpty();
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

    function getTablespaceKeys(TLType.Storage storage s) internal constant returns (bytes32[]) {
        return s.tsmis;
    }

    modifier unqueueOnExecution(TLType.Storage storage s, TLType.Node storage n){
        bool queued = n.unqueue(s);
        _;
        if(queued) n.queue(s);
    }

}