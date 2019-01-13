var util = require('util');
var path = require('path');
var hfc = require('fabric-client');

var file = 'network-config%s.yaml';

var env = process.env.TARGET_NETWORK;
if (env)
	file = util.format(file, '-' + env);
else
	file = util.format(file, '');
// indicate to the application where the setup file is located so it able
// to have the hfc load it to initalize the fabric client instance
hfc.setConfigSetting('network-connection-profile-path',path.join(__dirname, 'artifacts' ,file));
hfc.setConfigSetting('Org1-connection-profile-path',path.join(__dirname, 'artifacts', 'org1.yaml'));
hfc.setConfigSetting('Org2-connection-profile-path',path.join(__dirname, 'artifacts', 'org2.yaml'));
hfc.setConfigSetting('Org3-connection-profile-path',path.join(__dirname, 'artifacts', 'org3.yaml'));
hfc.setConfigSetting('Org4-connection-profile-path',path.join(__dirname, 'artifacts', 'org4.yaml'));
hfc.setConfigSetting('Org5-connection-profile-path',path.join(__dirname, 'artifacts', 'org5.yaml'));
hfc.setConfigSetting('Org6-connection-profile-path',path.join(__dirname, 'artifacts', 'org6.yaml'));
hfc.setConfigSetting('Org7-connection-profile-path',path.join(__dirname, 'artifacts', 'org7.yaml'));
hfc.setConfigSetting('Org8-connection-profile-path',path.join(__dirname, 'artifacts', 'org8.yaml'));
hfc.setConfigSetting('Org9-connection-profile-path',path.join(__dirname, 'artifacts', 'org9.yaml'));
// some other settings the application might need to know
hfc.addConfigFile(path.join(__dirname, 'config.json'));
