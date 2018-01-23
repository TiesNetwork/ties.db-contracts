pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";


library TLIndex {
    using TiesLibString for string;

    function getName(TLType.Index storage index) internal view returns (string) {
        require(!isEmpty(index));
        return index.name;
    }

    function isEmpty(TLType.Index storage index) internal view returns (bool) {
        return index.iType != 0;
    }

    function export(TLType.Index storage index) internal view returns (byte iType, string name, bytes32[] fields) {
        iType = index.iType;
        name = index.name;
        fields = index.fields;
    }
}