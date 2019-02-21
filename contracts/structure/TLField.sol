pragma solidity ^0.5.0;

import "./Util.sol";
import "./TLType.sol";


library TLField {
    using TiesLibString for string;

    function isEmpty(TLType.Field storage f) internal view returns (bool) {
        return f.idx == 0;
    }

    function getName(TLType.Field storage f) internal view returns (string memory) {
        require(!isEmpty(f));
        return f.name;
    }

    function export(TLType.Field storage f) internal view returns (string memory name, string memory fType, bytes memory def) {
        name = f.name;
        fType = f.fType;
        def = f.fDefault;
    }
}