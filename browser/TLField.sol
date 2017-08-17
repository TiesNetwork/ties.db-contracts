pragma solidity ^0.4.15;

import "browser/Util.sol";
import "browser/TLType.sol";

library TLField {

    using TiesLibAddress for address;

    function isSet(TLType.Field storage f) constant public returns (bool) {
        return !address(f.t.ts.rs).isFree();
    }

    function getFieldName(TLType.Field storage f) constant internal returns (string) {
        require(isSet(f));
        return f.name;
    }
}