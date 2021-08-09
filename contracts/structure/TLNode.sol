pragma solidity ^0.5.0;

import "./Util.sol";
import "./TLType.sol";
import "./TLRanges.sol";

library TLNode {
    using TLRanges for TLType.Ranges;

    function unqueue(TLType.Node storage n, TLType.Storage storage s) public returns (bool){
        if (n.queueIdx > 0) { //If the node is in queue, delete it from queue
            address[] storage arr = s.queue;
            assert(arr.length > 0); //If we are here then there must be table in array
            uint idx = uint(n.queueIdx) - 1; //One based
            if (arr.length > 1 && idx != arr.length-1) {
                arr[idx] = arr[arr.length-1];
                s.nm[arr[idx]].queueIdx = idx + 1; //One based
            }
            delete arr[arr.length-1];
            arr.length--;
            n.queueIdx = 0; //The node is not in queue
        }
        return n.queueIdx > 0;
    }

    function queue(TLType.Node storage n, TLType.Storage storage s) public {
        if (n.queueIdx == 0) { //If the node is not in queue, add it to queue
            address[] storage arr = s.queue;
            arr.push(s.nmis[uint(n.idx - 1)]);
            n.queueIdx = arr.length;
        }
    }

    function distributeRange(TLType.Node storage n, bytes32 tKey, uint32 divider, uint32 remainder) public {
        TLType.Ranges storage rs = n.trm.map[tKey];
        if(rs.idx == 0){
            rs.idx = n.trm.idx.push(tKey);
            rs.ranges.length = 0;

            n.trm.map[tKey] = rs;
        }

        rs.ranges.push(TLType.Range({ divider: divider, remainder: remainder }));
    }

    function findRange(TLType.Node storage n, bytes32 tKey, uint32 divider, uint32 remainder) public view returns (uint){
        TLType.Ranges storage rs = n.trm.map[tKey];
        require(rs.idx > 0);
        return rs.findRange(divider, remainder);
    }

    function deleteRange(TLType.Node storage n, bytes32 tKey, uint32 divider, uint32 remainder) public returns (bool){
        TLType.Ranges storage rs = n.trm.map[tKey];
        require(rs.idx > 0);
        rs.deleteRange(divider, remainder);

        if (rs.ranges.length == 0) {
            //No more ranges for this table. We have to remove table mapping

        }
        uint idx = findRange(n, tKey, divider, remainder);
        if (idx > 0)
            deleteTable(n, tKey);

        return idx > 0;
    }

    function deleteTable(TLType.Node storage cont, bytes32 tKey) public {
        bytes32[] storage arr = cont.trm.idx;

        TLType.Ranges storage item = cont.trm.map[tKey];
        require(!item.isEmpty() && item.ranges.length == 0); //Can delete only table without ranges

        assert(arr.length > 0); //If we are here then there must be table in array
        uint256 idx = item.idx;
        if (arr.length > 1 && idx != arr.length-1) {
            arr[idx] = arr[arr.length-1];
            cont.trm.map[arr[idx]].idx = idx;
        }

        delete arr[arr.length-1];
        arr.length--;

        delete cont.trm.map[tKey];
    }

    function displaceBy(TLType.Node storage n, TLType.Node storage r) public {
        r.trm = n.trm;
        delete n.trm;
    }

    function getRanges(TLType.Node storage n, bytes32 tKey) internal view returns (TLType.Ranges storage) {
        TLType.Ranges storage rs = n.trm.map[tKey];
        require(!rs.isEmpty());
        return rs;
    }

    function getRangesPack(TLType.Node storage n, bytes32 tKey) internal view returns (uint64[] memory) {
        TLType.Ranges storage rs = n.trm.map[tKey]; //In case the node does not contain table this function should return empty array
        return rs.export();
    }

    function isEmpty(TLType.Node storage n) internal view returns (bool) {
        return n.idx == 0;
    }

    function export(TLType.Node storage n) internal view returns (bool inQueue, bytes32[] memory tables) {
        inQueue = n.queueIdx > 0;
        tables = n.trm.idx;
    }

}