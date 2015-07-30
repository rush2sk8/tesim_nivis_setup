DELETE FROM Properties WHERE `Key`='Version';
REPLACE INTO Properties(`Key`, Value) VALUES('SchemaVersion', '1.0.18');
REPLACE INTO Properties(`Key`, Value) VALUES('DataVersion', '1.0.18');

ALTER TABLE DeviceSetPublishersLog ADD COLUMN Message VARCHAR(500);

--discovery burst config
INSERT INTO CommandSet(CommandCode,CommandName, ParameterCode, ParameterDescription,IsVisible)
VALUES(126, 'Auto Detect Burst Configuration', 64, 'Target Device ID', 1);


