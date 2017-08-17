pragma solidity ^0.4.15;

import "browser/TiesDBAPI.sol";

library TLType {

    struct Field {
        Table t;
        string name;
        uint256 fmi;
    }

    struct Table {
        Tablespace ts;
        string name;
        uint256 tmi;
        mapping(bytes32 => Field) fm;
        bytes32[] fmis;
    }

    struct Tablespace {
        TiesDBRestrictions rs;
        string name;
        uint256 tsmi;
        mapping(bytes32 => Table) tm;
        bytes32[] tmis;
    }

    struct Storage {
        mapping(bytes32 => Tablespace) tsm;
        bytes32[] tsmis;
    }
}