pragma solidity ^0.4.15;

import "browser/TiesDBAPI.sol";

library TLType {

    struct Field {
        bool set;
        uint256 fmi;
        Table t;
        string name;
    }

    struct Table {
        bool set;
        uint256 tmi;
        Tablespace ts;
        string name;
        bytes32[] fmis;
        mapping(bytes32 => Field) fm;
    }

    struct Tablespace {
        bool set;
        uint256 tsmi;
        TiesDBRestrictions rs;
        string name;
        bytes32[] tmis;
        mapping(bytes32 => Table) tm;
    }

    struct Storage {
        bytes32[] tsmis;
        mapping(bytes32 => Tablespace) tsm;
    }
}