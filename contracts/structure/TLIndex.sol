pragma solidity ^0.5.0;

import "./Util.sol";
import "./TLType.sol";


library TLIndex {
    using TiesLibString for string;

    function isEmpty(TLType.Index storage index) internal view returns (bool) {
        return index.idx == 0;
    }

    function getName(TLType.Index storage index) internal view returns (string memory) {
        require(!isEmpty(index));
        return index.name;
    }

    function export(TLType.Index storage index) internal view returns (string memory name, uint8 iType, bytes32[] memory fields) {
        iType = index.iType;
        name = index.name;
        fields = index.fields;
    }
}