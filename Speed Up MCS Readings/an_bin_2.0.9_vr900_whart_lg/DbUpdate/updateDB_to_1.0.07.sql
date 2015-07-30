DELETE FROM Properties WHERE `Key`='Version';
REPLACE INTO Properties(`Key`, Value) VALUES('SchemaVersion', '1.0.07');
REPLACE INTO Properties(`Key`, Value) VALUES('DataVersion', '1.0.07');


DROP TABLE WHResponseDataBuffer;

CREATE TABLE BurstMessages
(
	DeviceID			INTEGER NOT NULL,
	BurstMessage		INTEGER NOT NULL,
	CommandNumber		INTEGER NOT NULL,
	UpdatePeriod		DOUBLE	NOT NULL,
	MaxUpdatePeriod		DOUBLE	NOT NULL,

	PRIMARY KEY(DeviceID,BurstMessage,CommandNumber)
);

CREATE TABLE BurstCounters
(
	DeviceID			INTEGER NOT NULL,
	BurstMessage		INTEGER NOT NULL,
	CommandNumber		INTEGER NOT NULL,
	LastUpdate			DATETIME NOT NULL,
	Received			INTEGER NOT NULL,
	Missed				INTEGER NOT NULL,

	PRIMARY KEY(DeviceID,BurstMessage,CommandNumber)
);


DROP TABLE DeviceScheduleLinks;
CREATE TABLE DeviceScheduleLinks
(
	SuperframeID	INTEGER NOT NULL,
	DeviceID		INTEGER NOT NULL,
	PeerID			INTEGER NOT NULL,
	SlotIndex		INTEGER NOT NULL,
	ChannelOffset	INTEGER NOT NULL,
	Transmit		INTEGER NOT NULL,
	Receive			INTEGER NOT NULL,
	Shared			INTEGER NOT NULL,
	LinkType		INTEGER NOT NULL,
	Timestamp		DATETIME NOT NULL,
	
	--PRIMARY KEY(SuperframeID,DeviceID,PeerID, SlotIndex)
);

--routes
INSERT INTO CommandSet(CommandCode,CommandName, ParameterDescription,IsVisible)
VALUES(120, 'Request Routes and SourceRoutes', NULL, 1);
--services
INSERT INTO CommandSet(CommandCode,CommandName, ParameterDescription,IsVisible)
VALUES(121, 'Request Services', NULL, 1);
--superframes
INSERT INTO CommandSet(CommandCode,CommandName, ParameterDescription,IsVisible)
VALUES(122, 'Request Superframes', NULL, 1);
--schedule_links
INSERT INTO CommandSet(CommandCode,CommandName, ParameterDescription,IsVisible)
VALUES(123, 'Request Schedule Links', NULL, 1);
