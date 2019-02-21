pragma solidity ^0.5.0;

import "./Util.sol";
import "./TLType.sol";


library TLTrigger {
    using TiesLibString for string;

    function isEmpty(TLType.Trigger storage tr) internal view returns (bool) {
        return tr.idx == 0;
    }

    function getName(TLType.Trigger storage tr) internal view returns (string memory) {
        require(!isEmpty(tr));
        return tr.name;
    }

    function export(TLType.Trigger storage tr) internal view returns (string memory name, bytes memory payload){
        name = tr.name;
        payload = tr.payload;
    }
}