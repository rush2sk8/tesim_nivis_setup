DELETE FROM Properties WHERE `Key`='Version';
REPLACE INTO Properties(`Key`, Value) VALUES('SchemaVersion', '1.0.06');
REPLACE INTO Properties(`Key`, Value) VALUES('DataVersion', '1.0.06');


ALTER TABLE Readings DROP COLUMN Status;
ALTER TABLE Readings ADD COLUMN Status INTEGER;


CREATE TABLE Routes
(
	RouteID				INTEGER NOT NULL,
	DeviceID 			INTEGER NOT NULL,
	PeerID				INTEGER NOT NULL,
	GraphID				INTEGER NOT NULL,
	SourceRoute			INTEGER NOT NULL,
	Timestamp			DATETIME NOT NULL,

	PRIMARY KEY  (RouteID,DeviceID)
);

CREATE TABLE SourceRoutes
(
	DeviceID 			INTEGER NOT NULL,
	RouteID				INTEGER NOT NULL,
	Devices				VARCHAR(64) NOT NULL,
	Timestamp			DATETIME NOT NULL,

	PRIMARY KEY  (RouteID,DeviceID)
);

CREATE TABLE Services
(
	ServiceID			INTEGER NOT NULL,
	DeviceID 			INTEGER NOT NULL,
	PeerID				INTEGER NOT NULL,
	ApplicationDomain	INTEGER NOT NULL,
	SourceFlag			INTEGER NOT NULL,
	SinkFlag			INTEGER NOT NULL,
	IntermittentFlag	INTEGER NOT NULL,
	Period				INTEGER NOT NULL,
	RouteID				INTEGER NOT NULL,
	Timestamp			DATETIME NOT NULL,

	PRIMARY KEY  (ServiceID,DeviceID)	
);

CREATE TABLE Superframes
(
	SuperframeID		INTEGER NOT NULL,
	DeviceID			INTEGER NOT NULL,
	NumberOfTimeSlots	INTEGER NOT NULL,
	Active				INTEGER NOT NULL,
	HandheldSuperframe	INTEGER NOT NULL,
	Timestamp			DATETIME NOT NULL,
	
	PRIMARY KEY(SuperframeID,DeviceID)
);

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
	
	PRIMARY KEY(SuperframeID,DeviceID,PeerID)
);

CREATE TABLE ClockSources
(
    DeviceID                    INTEGER NOT NULL,
    PeerID                      INTEGER NOT NULL,
    ClockSource                 INTEGER NOT NULL,

    PRIMARY KEY(DeviceID, PeerID)
);

