#!/usr/bin/env python3

import sys
import json
import tinytuya

with open(sys.path[0] + "/tuya_devices.json") as jsonFile:
     jsonData = json.load(jsonFile)
jsonFile.close()

dn = int(sys.argv[1])
did = jsonData[dn]["id"]
ip = jsonData[dn]["ip"]
key = jsonData[dn]["key"]

lamp = tinytuya.BulbDevice(did, ip, key)
#lamp.version = jsonData[dn]["ver"]
#lamp.bulb_type = jsonData[dn]["bulb_type"]
lamp.set_version(jsonData[dn]["ver"])

sn = int(sys.argv[2])
if "temp" in jsonData[dn]["shortcuts"][sn]:
	temp = (jsonData[dn]["shortcuts"][sn]["temp"] - 2700) // ((jsonData[dn]["max_temp"] - 2700)/100)
	if "bright" in jsonData[dn]["shortcuts"][sn]:
		lamp.set_white_percentage(jsonData[dn]["shortcuts"][sn]["bright"], temp)
	else:
		lamp.set_colourtemp_percentage(temp)
elif "bright" in jsonData[dn]["shortcuts"][sn]:
	lamp.set_brightness_percentage(jsonData[dn]["shortcuts"][sn]["bright"])

#print(lamp.state())

