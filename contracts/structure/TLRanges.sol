pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";


library TLRanges {

    function findRange(TLType.Ranges storage rs, uint32 divider, uint32 remainder) public view returns (uint){
        for(int i=int(rs.ranges.length)-1; i>=0; --i){
            var r = rs.ranges[uint(i)];
            if (r.divider == divider && r.remainder == remainder) {
                return uint(i+1);
            }
        }

        return 0;
    }

    function deleteRange(TLType.Ranges storage rs, uint32 divider, uint32 remainder) public returns (bool){
        uint idx = findRange(rs, divider, remainder);
        if (idx > 0) {
            var arr = rs.ranges;

            if (arr.length > idx) {
                arr[idx - 1] = arr[arr.length - 1];
            }

            delete arr[arr.length - 1];
            --arr.length;
        }

        return idx > 0;
    }

    function isEmpty(TLType.Ranges rs) internal pure returns (bool) {
        return rs.idx == 0;
    }

}