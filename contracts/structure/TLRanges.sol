pragma solidity ^0.5.0;

import "./Util.sol";
import "./TLType.sol";


library TLRanges {

    function findRange(TLType.Ranges storage rs, uint32 divider, uint32 remainder) public view returns (uint){
        for(int i=int(rs.ranges.length)-1; i>=0; --i){
            TLType.Range storage r = rs.ranges[uint(i)];
            if (r.divider == divider && r.remainder == remainder) {
                return uint(i+1);
            }
        }

        return 0;
    }

    function deleteRange(TLType.Ranges storage rs, uint32 divider, uint32 remainder) public returns (bool){
        uint idx = findRange(rs, divider, remainder);
        if (idx > 0) {
            TLType.Range[] storage arr = rs.ranges;

            if (arr.length > idx) {
                arr[idx - 1] = arr[arr.length - 1];
            }

            delete arr[arr.length - 1];
            --arr.length;
        }

        return idx > 0;
    }

    function isEmpty(TLType.Ranges storage rs) internal view returns (bool) {
        return rs.idx == 0;
    }

    function export(TLType.Ranges storage rs) internal view returns (uint64[] memory) {
        uint64[] memory pack = new uint64[](rs.ranges.length);
        for(uint i=0; i<pack.length; ++i){
            TLType.Range storage r = rs.ranges[i];
            pack[i] = (uint64(r.divider) << 32) | uint64(r.remainder);
        }
        return pack;
    }

}