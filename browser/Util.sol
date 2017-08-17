pragma solidity ^0.4.15;

library TiesLibString {

    bytes32 private constant emptyHash = sha3();

    function hash(string s) internal constant returns (bytes32) {
        return sha3(s);
    }

    using TiesLibString for string;

    function equals(string s, string x) internal constant returns (bool) {
        return bytes(s).length == bytes(x).length && s.hash() == x.hash();
    }

    function isEmpty(string s) internal constant returns (bool) {
        return s.hash() == emptyHash;
    }
}

library TiesLibAddress {
    
    address private constant freeAddress = address(0);

    function isFree(address s) internal constant returns (bool) {
        return s == freeAddress;
    }
}