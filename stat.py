#!/usr/bin/env python3

import sys
import json
import tinytuya

result = []

with open(sys.path[0] + "/tuya_devices.json") as jsonFile:
     jsonData = json.load(jsonFile)
jsonFile.close()

def parseState(dev, data):
  if "Error" in data:
      return {}
  else:
      bright = (data["brightness"] - 10) / 9.9
      temp = (data["colourtemp"] *((dev["max_temp"] - 2700)/1000)) + 2700
      return {"power": data["is_on"], "bright": bright, "temp": temp}

def getStat(dev):
  did = dev["id"]
  ip = dev["ip"  ]
  key = dev["key"]
  bulb = tinytuya.BulbDevice(did, ip, key)
  bulb.set_socketRetryLimit(1)
  bulb.set_socketTimeout(3)
  #bulb.set_socketPersistent(True)
  bulb.set_bulb_type(dev["bulb_type"])
  bulb.set_version(dev["ver"])
  data = bulb.state()
  return parseState(dev, data)

if len(sys.argv) > 1:
    result = getStat(jsonData[int(sys.argv[1])])
else:
    for dev in jsonData:
        if "group" in dev:
            result.append({})
        else:
            result.append(getStat(dev))

print(json.dumps(result))

