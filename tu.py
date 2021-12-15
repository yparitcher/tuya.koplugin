#!/usr/bin/env python3

import sys
import json
import tinytuya

with open(sys.path[0] + "/tuya_devices.json") as jsonFile:
     jsonData = json.load(jsonFile)
jsonFile.close()

def parseState(data):
  if "Error" in data:
      return {}
  else:
      bright = (data["brightness"] - 10) / 9.9
      temp = ((data["colourtemp"]/10) *((dev["max_temp"] - 2700)/100)) + 2700
      return {"power": data["is_on"], "bright": bright, "temp": temp}

dn = int(sys.argv[1])
dev = jsonData[dn]
did = jsonData[dn]["id"]
ip = jsonData[dn]["ip"]
key = jsonData[dn]["key"]

bulb = tinytuya.BulbDevice(did, ip, key)
bulb.set_socketRetryLimit(1)
bulb.set_socketTimeout(3)
bulb.set_socketPersistent(True)
bulb.set_bulb_type(jsonData[dn]["bulb_type"])
bulb.set_version(jsonData[dn]["ver"])

sn = int(sys.argv[2])
sc = dev["shortcuts"][sn]
if "temp" in jsonData[dn]["shortcuts"][sn]:
	temp = (jsonData[dn]["shortcuts"][sn]["temp"] - 2700) // ((jsonData[dn]["max_temp"] - 2700)/100)
	if "bright" in jsonData[dn]["shortcuts"][sn]:
		bulb.set_white_percentage(jsonData[dn]["shortcuts"][sn]["bright"], temp)
	else:
		bulb.set_colourtemp_percentage(temp)
elif "bright" in jsonData[dn]["shortcuts"][sn]:
	bulb.set_brightness_percentage(jsonData[dn]["shortcuts"][sn]["bright"])

data = bulb.state()
print(json.dumps(parseState(data)))

