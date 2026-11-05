import json
from copy import deepcopy

decoder = json.JSONDecoder()

import os

# pyright: reportUnknownVariableType=false
# pyright: reportUnknownArgumentType=false
# pyright: reportUnknownParameterType=false

script_dir = os.path.dirname(os.path.abspath(__file__))

print(script_dir)

output = ""

# with open(script_dir + "/" + "api_dump.json") as file:
# contents = file.read()
# api_dump = decoder.decode(contents)["Classes"]


with open(script_dir + "/" + "removed.json") as file:
    contents = file.read()
    removed = decoder.decode(contents)


def print_dict(d, nest: int):
    global output
    if isinstance(d, dict):
        for k, i in d.items():

            output += f"{' ' * (nest * 2)}{k}:\n"
            print_dict(i, nest + 1)
    elif isinstance(d, list):
        # output += f"{' ' * (nest * 2)}\n"

        for i in d:
            print_dict(i, nest + 1)
    else:
        output += f"{' ' * (nest * 2)}{d},\n"


with open(script_dir + "/" + "data.json") as file:
    contents = file.read()
    new_data = decoder.decode(contents)
    new_data_classes = new_data["Classes"]
    new_data_enums = new_data["Enums"]

with open(script_dir + "/" + "data_old.json") as file:
    contents = file.read()
    old_data = decoder.decode(contents)
    old_data_classes = old_data["Classes"]
    old_data_enums = old_data["Enums"]

print("ROBLOX CHANGES")

for key, data in new_data_classes.items():
    if key not in old_data_classes:
        print(f"NEW CLASS: {key}")
    elif data != old_data_classes[key]:
        tmp = deepcopy(data)

        print(f"CHANGED CLASS: {key}")
        old_p = old_data_classes[key]["Properties"]
        for k, i in data["Properties"].items():
            if not k in old_p.keys():
                print(f"    NEW PROPERTY: {k}")
            elif i != old_p[k]:
                print(f"    CHANGED PROPERTY: {k}")
                try:
                    print(f"        Tags: {old_p[k]["Tags"]} -> {i["Tags"]}")
                except:
                    print(f"        Tags: [] -> {i["Tags"]}")

        for k in old_p.keys():
            if not k in data["Properties"].keys():
                print(f"    REMOVED PROPERTY: {k} -> {removed["Classes"][k]}")

for key in old_data_classes.keys():
    if key not in new_data_classes.keys():
        print(f"REMOVED CLASS: {key} -> {removed["Classes"][key]}")

for key, data in new_data_enums.items():
    if not key in old_data_enums.keys():
        print(f"NEW ENUM: {key}")
    elif data != old_data_enums[key]:
        print(f"CHANGED ENUM: {key}")
        for k, i in data.items():
            if not k in old_data_enums[key].keys():
                print(f"    NEW ENUM FIELD: {k}")
            elif i != old_data_enums[key][k]:
                print(
                    f"    NEW ENUM FIELD VALUE: {k}\n        {old_data_enums[key][k]} -> {i}"
                )
        for k, i in old_data_enums[key].items():
            if not k in data.keys():
                name = f"{key}.{k}"
                if name in removed["Enums"].keys():
                    print(f"    REMOVED ENUM FIELD: {name} -> {removed["Enums"][name]}")
                else:
                    print(f"    REMOVED ENUM FIELD: {name} -> REMOVED")

for key, data in old_data_enums.items():
    if not key in new_data_enums.keys():
        if key in removed["Enums"].keys():
            print(f"REMOVED ENUM: {key} -> {removed["Enums"][key]}")
        else:
            print(f"REMOVED ENUM: {key} -> REMOVED")
