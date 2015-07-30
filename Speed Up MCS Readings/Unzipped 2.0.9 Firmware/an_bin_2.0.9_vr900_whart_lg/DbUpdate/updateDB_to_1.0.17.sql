DELETE FROM Properties WHERE `Key`='Version';
REPLACE INTO Properties(`Key`, Value) VALUES('SchemaVersion', '1.0.17');
REPLACE INTO Properties(`Key`, Value) VALUES('DataVersion', '1.0.17');

DROP TABLE IF EXISTS ClockSources;

DROP TABLE IF EXISTS DeviceSetPublishersLog;
CREATE TABLE DeviceSetPublishersLog
(
    DeviceID            INTEGER NOT NULL PRIMARY KEY,
    State               INTEGER,
    Error               VARCHAR(100)
);



