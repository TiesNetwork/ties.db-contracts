pragma solidity ^0.4.15;

import "./TiesDBAPI.sol";


library TLType {

    struct Trigger {
        uint256 idx; //Trigger mapping index, one based
        Table t;
        string name;

        bytes payload;
    }

    struct Field {
        uint256 idx; //One based
        Table t;
        string name;

        string fType; //String identifying the type of this field
        bytes fDefault; //Default value
    }

    struct Table {
        uint256 idx; //One based
        Tablespace ts;
        string name;

        bytes32[] fmis; //Field mapping indexes
        mapping(bytes32 => Field) fm; //Field mapping

        bytes32[] trmis; //Trigger mapping indexes
        mapping(bytes32 => Trigger) trm; //Trigger mapping

        bytes32[] imis; //Index mapping indexes
        mapping(bytes32 => Index) im; //Index mapping

        uint32 replicas;
        uint32 ranges;

        address[] nodes; //Nodes storing the table
    }

    struct Tablespace {
        uint256 idx; //One based
        TiesDBRestrictions rs;
        string name;
        bytes32[] tmis;
        mapping(bytes32 => Table) tm;
    }

    struct Storage {
        bytes32[] tsmis; //Tablespace mapping IDs
        mapping(bytes32 => Tablespace) tsm;
        mapping(bytes32 => bytes32) table_to_tablespace; //Table to tablespace relation

        address[] nmis; //Nodes mapping ids
        mapping(address => Node) nm; //Nodes mapping

        address[] queue; //Queue for registering ranges
        uint128 queue_head; //The head of the queue (0 based)
    }

    struct Ranges {
        uint idx; //One based
        Range[] ranges;
    }

    struct Range {
        uint32 divider;
        uint32 remainder;
    }

    struct Node {
        uint128 idx; //Index in all nodes array (1 based)
        int128 queue_idx; //Index in queue (1 based)

        mapping(bytes32 => Ranges) trm; //Table range mapping: tKey => Ranges
        bytes32[] tmis; //Tables mapping indexes
    }

    struct Index {
        uint128 idx; //One based
        uint8 iType; //0 - empty, 0x1 - primary, 0x2 - internal, 0x4 - external

        string name;
        bytes32[] fields;
    }
}