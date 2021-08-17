pragma solidity ^0.5.0;

import "./TiesDBAPI.sol";


library TLType {

    struct Trigger {
        uint idx; //Trigger mapping index, one based
        Table t;
        string name;

        bytes payload;
    }

    struct Field {
        uint idx; //One based
        Table t;
        string name;

        string fType; //String identifying the type of this field
        bytes fDefault; //Default value
    }

    struct Table {
        uint idx; //One based
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

        uint[] nid; //Node global ids (0 based)
        mapping(uint => uint) nidm; //Node global id mapping (1 based) subtraction needed
    }

    struct Tablespace {
        uint idx; //One based
        TiesDBRestrictions rs;
        string name;
        bytes32[] tmis; //Table hash mapping index
        mapping(bytes32 => Table) tm; //Table hash mapping
    }

    struct Storage {
        bytes32[] tsmis; //Tablespace mapping IDs
        mapping(bytes32 => Tablespace) tsm;
        mapping(bytes32 => bytes32) table_to_tablespace; //Table to tablespace relation

        address[] nmis; //Nodes mapping ids
        mapping(address => uint[]) nim; //Nodes id mapping (1 based) subtraction needed
        mapping(address => Node) nm; //Nodes mapping

        mapping(uint => TableRangeMap) trm; //Map of table ranges for node id

        address[] queue; //Queue for registering ranges
        uint queueHead; //The head of the queue (0 based)
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
        uint idx; //Index in all nodes array (1 based)
        uint queueIdx; //Index in queue (1 based)
    }

    struct TableRangeMap {
        bytes32[] idx; //Tables range mapping indexes
        mapping(bytes32 => Ranges) map; //Table range mapping: tKey => Ranges
    }

    struct Index {
        uint idx; //One based
        uint8 iType; //0 - empty, 0x1 - primary, 0x2 - internal, 0x4 - external

        string name;
        bytes32[] fields;
    }
}