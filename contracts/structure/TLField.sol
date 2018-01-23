pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";


library TLField {
    using TiesLibString for string;

    function isEmpty(TLType.Field storage f) internal view returns (bool) {
        return f.name.isEmpty();
    }

    function getName(TLType.Field storage f) internal view returns (string) {
        require(!isEmpty(f));
        return f.name;
    }

    function export(TLType.Field storage f) internal view returns (string name, string fType, bytes def) {
        name = f.name;
        fType = f.fType;
        def = f.fDefault;
    }
}