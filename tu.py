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

def executeSc(bulb, max_temp, sc):
    if "temp" in sc:
        temp = (sc["temp"] - 2700) // ((max_temp - 2700)/100)
        if "bright" in sc:
            bulb.set_white_percentage(sc["bright"], temp)
        else:
            bulb.set_colourtemp_percentage(temp)
    elif "bright" in sc:
        if sc["bright"] == 1:
            bulb.set_brightness(10)
        else:
            bulb.set_brightness_percentage(sc["bright"])

def parseState(bulb, max_temp):
    data = bulb.state()
    if "Error" in data:
        return {}
    else:
        bright = (data["brightness"] - 10) / 9.9
        temp = ((data["colourtemp"]/10) *((max_temp - 2700)/100)) + 2700
        return json.dumps({"power": data["is_on"], "bright": bright, "temp": temp})

with open(sys.path[0] + "/tuya_devices.json") as jsonFile:
    jsonData = json.load(jsonFile)
jsonFile.close()

dev = jsonData[int(sys.argv[1])]
devs = []
bulbs = []
states = []

if "group" in dev:
    for did, idx in dev["idx"].items():
        if jsonData[idx]["id"] == did:
            devs.append(jsonData[idx])
else:
    devs.append(dev)

for device in devs:
    bulbs.append(getBulb(device))

if len(sys.argv) == 3:
    sc = dev["shortcuts"][int(sys.argv[2])]
    for bulb in bulbs:
        executeSc(bulb, dev["max_temp"], sc)
elif len(sys.argv) == 4 and sys.argv[2] == "M" :
    sc = { "bright": int(sys.argv[3]) }
    for bulb in bulbs:
        executeSc(bulb, dev["max_temp"], sc)

for bulb in bulbs:
    states.append(parseState(bulb, dev["max_temp"]))

if all(x==states[0] for x in states):
    print(states[0])
else:
    print({})

