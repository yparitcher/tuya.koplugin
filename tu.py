#!/usr/bin/env python3

import sys
import json
import tinytuya

def getBulb(dev):
    bulb = tinytuya.BulbDevice(dev["id"], dev["ip"], dev["key"])
    bulb.set_socketRetryLimit(1)
    bulb.set_socketTimeout(3)
    bulb.set_socketPersistent(True)
    bulb.set_bulb_type(dev["bulb_type"])
    bulb.set_version(dev["ver"])
    return bulb

def executeSc(bulb, sc):
    if "temp" in sc:
        temp = (sc["temp"] - 2700) // ((dev["max_temp"] - 2700)/100)
        if "bright" in sc:
            bulb.set_white_percentage(sc["bright"], temp)
        else:
            bulb.set_colourtemp_percentage(temp)
    elif "bright" in sc:
        bulb.set_brightness_percentage(sc["bright"])

def parseState(bulb):
    data = bulb.state()
    if "Error" in data:
        return {}
    else:
        bright = (data["brightness"] - 10) / 9.9
        temp = ((data["colourtemp"]/10) *((dev["max_temp"] - 2700)/100)) + 2700
        return json.dumps({"power": data["is_on"], "bright": bright, "temp": temp})

with open(sys.path[0] + "/tuya_devices.json") as jsonFile:
     jsonData = json.load(jsonFile)
jsonFile.close()

dev = jsonData[int(sys.argv[1])]
bulb = getBulb(dev)

sc = dev["shortcuts"][int(sys.argv[2])]
executeSc(bulb, sc)

print(parseState(bulb))

