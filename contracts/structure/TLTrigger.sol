pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";


library TLTrigger {
    using TiesLibString for string;

    function getTriggerName(TLType.Trigger storage tr) internal constant returns (string) {
        require(!isEmpty(tr));
        return tr.name;
    }

    function isEmpty(TLType.Trigger storage tr) internal constant returns (bool) {
        return tr.name.isEmpty();
    }
}