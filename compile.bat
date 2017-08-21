@call %~dp0../env.bat

call solcjs --optimize --bin -o target/bin browser/TiesDB.sol browser/TiesDBAPI.sol browser/TLField.sol browser/TLStorage.sol browser/TLTable.sol browser/TLTblspace.sol browser/TLType.sol browser/Util.sol
call solcjs --abi -o target/abi browser/TiesDB.sol browser/TiesDBAPI.sol browser/TLField.sol browser/TLStorage.sol browser/TLTable.sol browser/TLTblspace.sol browser/TLType.sol browser/Util.sol