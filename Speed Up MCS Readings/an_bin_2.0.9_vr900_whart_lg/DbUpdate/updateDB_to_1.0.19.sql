DELETE FROM Properties WHERE `Key`='Version';
REPLACE INTO Properties(`Key`, Value) VALUES('SchemaVersion', '1.0.19');
REPLACE INTO Properties(`Key`, Value) VALUES('DataVersion', '1.0.19');

CREATE TABLE Firmwares
(
   FirmwareID           INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   FileName             VARCHAR(250) NOT NULL,
   Version              VARCHAR(11) NOT NULL,
   Description          VARCHAR(1000),
   UploadDate           DATETIME,
   UploadStatus         INTEGER NOT NULL DEFAULT 0,   
   UploadRetryCount     INTEGER NOT NULL DEFAULT -1,   
   FileSize             INTEGER NOT NULL DEFAULT -1,   
   LastFailedUploadTime DATETIME
);

CREATE TABLE FirmwareUpdates
(
    FwUpdateID		INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    DeviceID            INTEGER,
    FwStatus            INTEGER,            /* Set from MCS to:   1-InProgress,  2-CancelInProgress, Updated by MH to:   3-Cancelled, 4-Completed, 5-Failed */
    CompletedPercent  	INTEGER NULL,       /* calculated & updated by MH */
    Speed               INTEGER NULL,       /* calculated & updated by MH in bytes/min*/
    AvgSpeed            INTEGER NULL,       /* calculated & updated by MH in bytes/min */
    StartedOn           DATETIME,           /* calculated by MCS when creating the record*/
    CompletedOn         DATETIME NULL,	    /* calculated by MH */
    FirmwareID          INTEGER NOT NULL DEFAULT -1 /* firmware id in firmwares table*/
);

INSERT INTO CommandSet(CommandCode,CommandName, ParameterCode, ParameterDescription,IsVisible)
VALUES(127, 'Firmware Upload', 94, 'FirmwareFileID', 1);

INSERT INTO CommandSet(CommandCode,CommandName, ParameterCode, ParameterDescription,IsVisible)
VALUES(128, 'Delete Firmware File', 94, 'FirmwareFileID', 1);

INSERT INTO CommandSet(CommandCode,CommandName, ParameterCode, ParameterDescription,IsVisible)
VALUES(129, 'Start Firmware Update', 97, 'TargetType', 1);
INSERT INTO CommandSet(CommandCode,CommandName, ParameterCode, ParameterDescription,IsVisible)
VALUES(129, 'Start Firmware Update', 95, 'EUI', 1);
INSERT INTO CommandSet(CommandCode,CommandName, ParameterCode, ParameterDescription,IsVisible)
VALUES(129, 'Start Firmware Update', 96, 'Mask', 1);
INSERT INTO CommandSet(CommandCode,CommandName, ParameterCode, ParameterDescription,IsVisible)
VALUES(129, 'Start Firmware Update', 94, 'FirmwareID', 1);

INSERT INTO CommandSet(CommandCode,CommandName, ParameterCode, ParameterDescription,IsVisible)
VALUES(130, 'Cancel Firmware Update', 98, 'FirmwareUpdateID', 1);

-- no more are used
DROP TABLE IF EXISTS DeviceSetPublishersLog;
DROP TABLE IF EXISTS BurstCounters;

-- change structure for Readings table
DROP TABLE IF EXISTS Readings;
CREATE TABLE Readings
(
    ChannelID               INTEGER NOT NULL,
    ReadingTime             DATETIME NOT NULL,
    Miliseconds             INTEGER NOT NULL DEFAULT 0,
    Value                   DOUBLE  NOT NULL,
    ValueType               INTEGER NOT NULL DEFAULT 0,               /* 0 - normal float, 1 - Infinity, 2 - NaN */
    Status                  INTEGER,
    CommandID               INTEGER NOT NULL,
    Received                INTEGER NOT NULL DEFAULT 0,
    Missed                  INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY (ChannelID)
);

-- remove LastRead and PublishStatus columns from Devices. No more is needed.
CREATE TABLE TmpDevices AS 
SELECT DeviceID, DeviceRole, DeviceCode, SoftwareRevision, Address64, DeviceTag, Nickname, DeviceStatus, DeviceLevel, RejoinCount, PowerSupplyStatus 
  FROM Devices;

DROP TABLE IF EXISTS Devices;
CREATE TABLE Devices
(
    DeviceID                INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 
    DeviceRole              INTEGER NOT NULL,                               /* 1 - NM (Network Manager), 2 - GW (Gateway), 4 - AP (Access Point), 10 - RD (Routing Device), -1 - Unknown */
    DeviceCode              INTEGER NOT NULL,
    SoftwareRevision        INTEGER NOT NULL,
    Address64               VARCHAR(50) NOT NULL,                           /*  Addr, ex: "001B:1EF9:8100:0002" */
    DeviceTag               VARCHAR(64) NOT NULL,                           /*  Tag (Latin1) save as hexstring */
    Nickname                INTEGER NOT NULL,
    DeviceStatus            INTEGER NOT NULL,
    DeviceLevel             INTEGER NOT NULL,                               /*  the level of device in topology */
    RejoinCount             INTEGER,
    PowerSupplyStatus       INTEGER NOT NULL
);

INSERT INTO Devices (DeviceID, DeviceRole, DeviceCode, SoftwareRevision, Address64, DeviceTag, Nickname, DeviceStatus, DeviceLevel, RejoinCount, PowerSupplyStatus) 
SELECT DeviceID, DeviceRole, DeviceCode, SoftwareRevision, Address64, DeviceTag, Nickname, DeviceStatus, DeviceLevel, RejoinCount, PowerSupplyStatus
  FROM TmpDevices;

DROP TABLE IF EXISTS TmpDevices;
