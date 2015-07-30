DELETE FROM Properties WHERE `Key`='Version';
REPLACE INTO Properties(`Key`, Value) VALUES('SchemaVersion', '1.0.11');
REPLACE INTO Properties(`Key`, Value) VALUES('DataVersion', '1.0.11');


ALTER TABLE BurstMessages ADD COLUMN SubDeviceID INTEGER NOT NULL default '0';
ALTER TABLE BurstMessages ADD COLUMN ExpandedType INTEGER NOT NULL default '0';


DELETE FROM CommandSet;

/* db cmds description section */
--topology
INSERT INTO CommandSet(CommandCode,CommandName, ParameterDescription,IsVisible)
VALUES(0, 'Request Topology', NULL, 1);
INSERT INTO CommandSet(CommandCode,CommandName, ParameterDescription,IsVisible)
VALUES(9, 'Subscribe for Topology Notification', NULL, 1);
--read
INSERT INTO CommandSet(CommandCode,CommandName,ParameterCode,ParameterDescription,IsVisible)
VALUES(1, 'Read Value', 10, 'CommandNo', 1);
INSERT INTO CommandSet(CommandCode,CommandName,ParameterDescription,IsVisible)
VALUES(3, 'Subscribe for Burst Notifications', NULL, 1);
--general command
INSERT INTO CommandSet(CommandCode,CommandName,ParameterCode,ParameterDescription,IsVisible)
VALUES(11, 'WH General Command', 92, 'CommandNo', 1);
INSERT INTO CommandSet(CommandCode,CommandName,ParameterCode,ParameterDescription,IsVisible)
VALUES(11, 'WH General Command', 93, 'DataBuffer - if required', 1);
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
INSERT INTO CommandSet(CommandCode,CommandName, ParameterCode, ParameterDescription,IsVisible)
VALUES(123, 'Request Schedule Links', 61, 'Target Device ID', 1);
--devices_neighb_health
INSERT INTO CommandSet(CommandCode,CommandName, ParameterCode, ParameterDescription,IsVisible)
VALUES(124, 'Request Device Neighbors Health', 62, 'Target Device ID', 1);
--devices_health
INSERT INTO CommandSet(CommandCode,CommandName, ParameterCode, ParameterDescription,IsVisible)
VALUES(125, 'Request Device Health', 63, 'Target Device ID', 1);
