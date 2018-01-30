pragma solidity ^0.4.15;


library TiesLibString {

    bytes32 private constant EMPTY_HASH = keccak256();

    function hash(string s) internal pure returns (bytes32) {
        return keccak256(s);
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