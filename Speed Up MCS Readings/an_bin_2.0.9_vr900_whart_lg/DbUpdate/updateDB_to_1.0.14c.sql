DELETE FROM Properties WHERE `Key`='Version';
REPLACE INTO Properties(`Key`, Value) VALUES('SchemaVersion', '1.0.14c');
REPLACE INTO Properties(`Key`, Value) VALUES('DataVersion', '1.0.14c');

DROP TABLE IF EXISTS Dashboard;
CREATE TABLE Dashboard
(
	SlotNumber       integer,
	DeviceID         integer,
	ChannelNo        integer,
	GaugeType        integer,
	MinValue         real,
	MaxValue         real
);
