pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";


library TLTrigger {
    using TiesLibString for string;

    function getTriggerName(TLType.Trigger storage tr) internal constant returns (string) {
        require(!tr.name.isEmpty());
        return tr.name;
    }
}