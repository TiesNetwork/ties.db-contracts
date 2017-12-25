pragma solidity ^0.4.15;


library TiesLibString {

    bytes32 private constant EMPTY_HASH = keccak256();

    function hash(string s) internal pure returns (bytes32) {
        return keccak256(s);
    }

    using TiesLibString for string;

    function equals(string s, string x) internal pure returns (bool) {
        bytes memory bs = bytes(s);
        bytes memory bx = bytes(x);
        return bs.length == bx.length && keccak256(bs) == keccak256(bx);
    }

    function isEmpty(string s) internal pure returns (bool) {
        bytes memory bs = bytes(s);
        return bs.length == 0;
    }
}


library TiesLibAddress {
    
    address private constant FREE_ADDRESS = address(0);

    function isFree(address s) internal pure returns (bool) {
        return s == FREE_ADDRESS;
    }
}