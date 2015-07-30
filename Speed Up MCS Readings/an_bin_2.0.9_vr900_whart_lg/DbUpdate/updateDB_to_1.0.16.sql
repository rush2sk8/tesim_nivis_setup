DELETE FROM Properties WHERE `Key`='Version';
REPLACE INTO Properties(`Key`, Value) VALUES('SchemaVersion', '1.0.16');
REPLACE INTO Properties(`Key`, Value) VALUES('DataVersion', '1.0.16');

CREATE TABLE TmpBurstMessages AS SELECT DeviceID, BurstMessage, CommandNumber, UpdatePeriod, MaxUpdatePeriod, SubDeviceMAC FROM BurstMessages;

DROP TABLE IF EXISTS BurstMessages;
CREATE TABLE BurstMessages
(
    DeviceID            INTEGER NOT NULL,
    BurstMessage        INTEGER NOT NULL,
    CommandNumber       INTEGER NOT NULL,
    UpdatePeriod        DOUBLE  NOT NULL,
    MaxUpdatePeriod     DOUBLE  NOT NULL,
    SubDeviceMAC        VARCHAR(50),
    PRIMARY KEY(DeviceID,BurstMessage,CommandNumber)
);

INSERT INTO BurstMessages (DeviceID, BurstMessage, CommandNumber, UpdatePeriod, MaxUpdatePeriod, SubDeviceMAC) 
SELECT DeviceID, BurstMessage, CommandNumber, UpdatePeriod, MaxUpdatePeriod, SubDeviceMAC 
  FROM TmpBurstMessages;

DROP TABLE IF EXISTS TmpBurstMessages;

DROP INDEX IF EXISTS IX_Alarms;
CREATE INDEX IX_Alarms ON Alarms(AlarmTime);


-- Update EUI64 format (XXXX:XXXX:XXXX:XXXX => XX-XX-XX-XX-XX-XX-XX-XX)
UPDATE Devices SET Address64 = CASE WHEN Address64 IS NOT NULL AND SUBSTR(Address64, 5, 1) = ':' AND SUBSTR(Address64, 10, 1) = ':' AND SUBSTR(Address64, 15, 1) = ':' 
                                    THEN SUBSTR(Address64, 1,2) || '-' || SUBSTR(Address64, 3,2) || '-' || SUBSTR(Address64, 6,2) || '-' || SUBSTR(Address64, 8,2) || '-' || 
                                         SUBSTR(Address64, 11,2) || '-' || SUBSTR(Address64, 13,2) || '-' || SUBSTR(Address64, 16,2) || '-'|| SUBSTR(Address64, 18,2) 
                                    ELSE Address64 END;

UPDATE BurstMessages SET SubDeviceMAC = CASE WHEN SubDeviceMAC IS NOT NULL AND SUBSTR(SubDeviceMAC, 5, 1) = ':' AND SUBSTR(SubDeviceMAC, 10, 1) = ':' AND SUBSTR(SubDeviceMAC, 15, 1) = ':' 
                                             THEN SUBSTR(SubDeviceMAC, 1,2) || '-' || SUBSTR(SubDeviceMAC, 3,2) || '-' || SUBSTR(SubDeviceMAC, 6,2) || '-' || SUBSTR(SubDeviceMAC, 8,2) || '-' || 
                                                  SUBSTR(SubDeviceMAC, 11,2) || '-' || SUBSTR(SubDeviceMAC, 13,2) || '-' || SUBSTR(SubDeviceMAC, 16,2) || '-'|| SUBSTR(SubDeviceMAC, 18,2) 
                                             ELSE SubDeviceMAC END;

