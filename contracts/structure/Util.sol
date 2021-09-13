pragma solidity ^0.5.0;

library TiesLibString {
    bytes32 private constant EMPTY_HASH = keccak256(abi.encodePacked());

    function hash(string memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(s));
    }

    function isEmpty(bytes32 h) internal pure returns (bool) {
        return h == EMPTY_HASH;
    }

    using TiesLibString for string;
}

library TiesLibAddress {
    address private constant FREE_ADDRESS = address(0);

    function isFree(address s) internal pure returns (bool) {
        return s == FREE_ADDRESS;
    }
}

library TiesLibSignature {
    string private constant SIGNATURE_HASH_PREFIX = "\x19Ethereum Signed Message:\n32";

    function prefixed(bytes32 h) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(SIGNATURE_HASH_PREFIX, h));
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return ecrecover(message, v, r, s);
    }
}
