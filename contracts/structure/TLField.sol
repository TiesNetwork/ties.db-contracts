pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";


library TLField {
    using TiesLibString for string;

    function getFieldName(TLType.Field storage f) internal constant returns (string) {
        require(!f.name.isEmpty());
        return f.name;
    }
}