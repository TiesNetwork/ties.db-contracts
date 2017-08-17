pragma solidity ^0.4.15;

import "browser/TLType.sol";

library TLField {

    function getFieldName(TLType.Field storage f) constant internal returns (string) {
        require(f.set);
        return f.name;
    }
}