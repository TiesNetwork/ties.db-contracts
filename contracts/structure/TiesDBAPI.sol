pragma solidity ^0.4.15;


interface TiesDBRestrictions {
    function canCreateTablespace(string tsName, address owner) public constant returns (bool);
    function canDeleteTablespace(string tsName, address owner) public constant returns (bool);
    function canCreateTable(string tsName, string tName, address owner) public constant returns (bool);
    function canDeleteTable(string tsName, string tName, address owner) public constant returns (bool);
    function canCreateField(string tsName, string tName, string fName, address owner) public constant returns (bool);
    function canDeleteField(string tsName, string tName, string fName, address owner) public constant returns (bool);
    function canCreateTrigger(string tsName, string tName, string fName, address owner) public constant returns (bool);
    function canDeleteTrigger(string tsName, string tName, string fName, address owner) public constant returns (bool);
}