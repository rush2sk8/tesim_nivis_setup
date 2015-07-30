DELETE FROM Properties WHERE `Key`='Version';
REPLACE INTO Properties(`Key`, Value) VALUES('SchemaVersion', '1.0.08');
REPLACE INTO Properties(`Key`, Value) VALUES('DataVersion', '1.0.08');


--it's a dummy needed script; it solves the update problem when a database of version 1.0.08 is encountered during an update process
