pragma solidity ^0.4.15;

import "./Util.sol";
import "./TLType.sol";


library TLTrigger {
    using TiesLibString for string;

    function getName(TLType.Trigger storage tr) internal view returns (string) {
        require(!isEmpty(tr));
        return tr.name;
    }

    function isEmpty(TLType.Trigger storage tr) internal view returns (bool) {
        return tr.name.isEmpty();
    }

    function export(TLType.Trigger storage tr) internal view returns (string name, bytes payload){
        name = tr.name;
        payload = tr.payload;
    }
}