pragma solidity ^0.4.0;

contract TiesDB {
    TiesTablespaceRestrictions public constant unrestricted = TiesTablespaceUnrestricted(0x692a70D2e424a56D2C6C27aA97D1a86395877b3A);
}

contract TiesDBEntity {

    TiesDB db;
    Type et;
    
    enum Type {//1
        Tablespace
    }

    function TiesDBEntity(Type entityType, TiesDB tiesDB) internal {
        db = tiesDB;
        et = entityType;
    }

}

interface TiesTablespaceRestrictions {
    function isTableAdditionAllowed() returns (bool);
    function isTableDeletionAllowed(Table table) returns (bool);
}

contract TiesTablespaceUnrestricted is TiesTablespaceRestrictions {

    function isTableAdditionAllowed() returns (bool){
        return true;
    }

    function isTableDeletionAllowed(Table table) returns (bool){
        return table != address(0);
    }
}

contract TiesTablespace is TiesDBEntity(TiesDBEntity.Type.Tablespace,TiesDB(0xbBF289D846208c16EDc8474705C748aff07732dB))  {

    address owner;
    TiesTablespaceRestrictions rst;

    mapping(bytes32 => Table) tables;

    function TiesTablespace(TiesTablespaceRestrictions restrictions) {
        owner = msg.sender;
        if(restrictions == address(0)){
            rst = db.unrestricted();
        }else{
            rst = restrictions;
        }
    }

    function addTable(string name, Table table) {
        require(rst.isTableAdditionAllowed());
        tables[sha3(name)] = table;
    }
    
    function getTable(string name) constant returns (Table) {
        return tables[sha3(name)];
    }
}

contract Table {

    TiesTablespace public ts;

    function Table(string name, TiesTablespace tablespace) {
        require(tablespace != address(0));
        require(tablespace.getTable(name) == address(0));
        ts = tablespace;
        ts.addTable(name, this);
    }

}