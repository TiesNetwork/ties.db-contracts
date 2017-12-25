pragma solidity ^0.4.15;

import "./TiesDBAPI.sol";


library TLType {

    struct Trigger {
        uint256 trmi; //Trigger mapping index
        Table t;
        string name;

        bytes payload;
    }

    struct Field {
        uint256 fmi;
        Table t;
        string name;

        string fType; //String identifying the type of this field
        bytes fDefault; //Default value
    }

    struct Table {
        uint256 tmi;
        Tablespace ts;
        string name;

        bytes32[] fmis; //Field mapping indexes
        mapping(bytes32 => Field) fm; //Field mapping

        bytes32[] trmis; //Trigger mapping indexes
        mapping(bytes32 => Trigger) trm; //Trigger mapping
    }

    struct Tablespace {
        uint256 tsmi;
        TiesDBRestrictions rs;
        string name;
        bytes32[] tmis;
        mapping(bytes32 => Table) tm;
    }

    struct Storage {
        bytes32[] tsmis; //Tablespace mapping IDs
        mapping(bytes32 => Tablespace) tsm;
    }
}