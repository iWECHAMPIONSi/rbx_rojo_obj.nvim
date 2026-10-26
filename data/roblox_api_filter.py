import json
from copy import deepcopy

superclass_dict = {}

decoder = json.JSONDecoder()

import os

# pyright: reportUnknownVariableType=false
# pyright: reportUnknownArgumentType=false
# pyright: reportUnknownParameterType=false

script_dir = os.path.dirname(os.path.abspath(__file__))

print(script_dir)


with open(script_dir + "/" + "full_api.json") as file:
    contents = file.read()
    full_api = decoder.decode(contents)

type_ref_dict = {
    "double": "Float64",
    "int": "Int32",
    "int64": "Int64",
    "float": "Float32",
    "bool": "Bool",
    "string": "String",
}

# full_api = full_api["Classes"]
lines: list[str] = []

superclasses: list[str] = []

member_dict = {}
final_dict = {
    "Classes": {"Instance": {"properties": {}}, "Object": {"properties": {}}},
    "Enums": {},
}

with open(script_dir + "/" + "intermediate_data1.json", "w") as file:
    json.dump(final_dict, file, indent=4)
member_keys = []


def add_removed_item(d, name, reason):
    if not name in d.keys():
        d[name] = []
    d[name].append(reason)


def look_for_key(nest, key: str, value: str, tags: list[str], superclass) -> None:
    if not key in nest.keys():
        for k in nest.keys():
            if k != "properties" and k != "tags" and k != "superclass":
                look_for_key(nest[k], key, value, tags, superclass)
    else:
        nest[key][value] = {
            "properties": member_dict[value],
            "tags": tags,
            "superclass": superclass,
        }


def print_members(properties, indents: int) -> None:
    for key, value in properties.items():
        if not isinstance(value, dict):
            print(f"{' ' * indents}{key}: {value}")
        else:
            print(f"{' ' * indents}{key}:")
            print_members(value, indents + 4)


def print_f_dict(nest, indents: int) -> None:
    for k, v in nest.items():
        if k != "properties" and k != "tags":
            print(f"{' ' * indents}{k}:")
            print_f_dict(v, indents + 4)
        elif k == "tags" or k == "superclass":
            print(f"{' ' * indents}{k}:")
            for t in v:
                print(f"{' ' * (indents + 4)}{t}")
        else:
            print(f"{' ' * indents}{k}:")
            print_members(v, indents + 4)


removed_items = {
    "Classes": {},
    "Enums": {},
}

# Item: Reason (tags)
#

blacklisted_value_types = ["Path2DControlPoint"]


def add_members(name: str, members_list):
    member_dict[name] = {}
    for d in members_list:
        if "MemberType" in d.keys():
            if d["MemberType"] != "Property":
                continue
            elif "Tags" in d.keys():
                if "ReadOnly" in d["Tags"]:
                    add_removed_item(removed_items["Classes"], d["Name"], "Readonly")
                    continue
                if "Hidden" in d["Tags"]:
                    add_removed_item(removed_items["Classes"], d["Name"], "Hidden")
                    continue
            if d["Name"] in ("Capabilities", "Parent", "UniqueId"):
                continue
            if d["ValueType"]["Category"] == "Class":
                continue
            if d["ValueType"]["Name"] in blacklisted_value_types:
                continue
            if d["ValueType"]["Name"] in type_ref_dict.keys():
                d["ValueType"]["Name"] = type_ref_dict[d["ValueType"]["Name"]]

        if "Tags" in d.keys():
            if "Deprecated" in d["Tags"]:
                add_removed_item(removed_items["Classes"], d["Name"], "Deprecated")
                continue
            if "Service" in d["Tags"]:
                continue

        member_dict[name][d["Name"]] = {}
        for key, value in d.items():
            if key == "Name":
                continue
            if key == "MemoryInstances":
                continue
            if key == "SimulationAccess":
                continue
            if key == "Security":
                continue
            if key == "Default":
                continue
            if key == "Serialization":
                continue
            if key == "ThreadSafety":
                continue
            if key == "Capabilities":
                continue
            if key not in member_keys:
                member_keys.append(key)
            member_dict[name][d["Name"]][key] = value


excluded_keys: list[str] = [
    "MemoryInstances",
    "SimulationAccess",
    "Security",
    "Default",
    "Serialization",
    "ThreadSafety",
    "Capabilities",
]


def loop_nest(d, spaces: int):
    string: str
    if isinstance(d, dict):
        if "MemberType" in d.keys():
            if d["MemberType"] != "Property":
                return
            if d["Name"] in ("Capabilities", "Parent", "UniqueId"):
                return
            if "Tags" in d.keys():
                if "ReadOnly" in d["Tags"]:
                    add_removed_item(removed_items["Classes"], d["Name"], "Readonly")
                    return
                if "Hidden" in d["Tags"]:
                    add_removed_item(removed_items["Classes"], d["Name"], "Hidden")
                    return
        if "Tags" in d.keys():
            if "Deprecated" in d["Tags"]:
                add_removed_item(removed_items["Classes"], d["Name"], "Deprecated")
                return
            if "Service" in d["Tags"]:
                return
        for key, value in d.items():
            if key in excluded_keys:
                continue
            if key == "Superclass":
                if not value in superclasses and value != "<<<ROOT>>>":
                    superclasses.append(value)
                    # print(superclasses)
                if value != "<<<ROOT>>>":
                    tags: list[str] = []
                    if "Tags" in d.keys():
                        tags = d["Tags"]

                    # print(value, d["Name"], tags, "\n")
                    look_for_key(final_dict["Classes"], value, d["Name"], tags, value)

            if isinstance(value, dict) or isinstance(value, list):
                if key == "Members":
                    add_members(d["Name"], value)
                string = f"{' ' * spaces * 4}{key}:"
                # print(string)
                # lines.append(string)
                loop_nest(value, spaces + 1)
            else:
                string = f"{' ' * spaces * 4}{key}: {value}"
                # print(string)
                lines.append(string)

    elif isinstance(d, list):
        for value in d:
            if value == "Security":
                continue
            if value == "Default":
                continue
            if value == "Serialization":
                continue
            if value == "ThreadSafety":
                continue
            if value == "Capabilities":
                continue

            if isinstance(value, dict) or isinstance(value, list):
                loop_nest(value, spaces + 1)
            else:
                string = f"{' ' * spaces * 4}{value}\n"
                # print(string)
                lines.append(string)
    else:
        string = f"{' ' * spaces * 4}{d}\n"
        # print(string)
        lines.append(string)


classes = full_api["Classes"]
enums = full_api["Enums"]


loop_nest(classes, 0)


# print(superclasses)

# with open(script_dir + "/" + "output.txt", "w") as file:
# file.writelines(lines)

final_dict["Classes"]["Instance"]["properties"] = member_dict["Instance"]

with open(script_dir + "/" + "intermediate_data2.json", "w") as file:
    json.dump(final_dict, file, indent=4)

print("")

# print(final_dict)

final_dict["Classes"]["Object"] = {}

with open(script_dir + "/" + "intermediate_data3.json", "w") as file:
    json.dump(final_dict, file, indent=4)

# print_f_dict(f_dict, 0)


def add_properties(nest, concat_dict):
    for key, _ in nest.items():
        if key == "properties" or key == "tags" or key == "superclass":
            continue
        nest[key]["properties"].update(concat_dict)
        add_properties(nest[key], nest[key]["properties"])


add_properties(
    final_dict["Classes"]["Instance"], final_dict["Classes"]["Instance"]["properties"]
)
with open(script_dir + "/" + "intermediate_data4.json", "w") as file:
    json.dump(final_dict, file, indent=4)

# print_f_dict(f_dict, 0)

dict_list = {
    "Classes": {},
    "Enums": {},
}

disallowed = ["NotCreatable", "Hidden", "Service", "NotBrowsable", "Deprecated"]

superclasses.clear()

blacklisted_names = [
    "plugin",
    "terrain",
    "studio",
    "debug",
    "avatar",
    "visualization",
    "statemachine",
    "breakpoint",
    "animationvalue",
    "operation",
    "tracker",
]

blacklisted_branches = [
    "properties",
    "tags",
    "superclass",
    "ParabolaAdornment",
    "Annotation",
    "BaseWrap",
    "TriangleMeshPart",
]

blacklisted_classes = [
    "AudioSearchParams",
    "BinaryStringValue",
    "CustomLog",
    "ExplorerFilter",
    "FeatureMatchingTable",
    "GetTextBoundsParams",
    "HiddenSurfaceRemovalAsset",
    "InternalSyncItem",
    "Noise",
    "Path3D",
    "Player",
    "RealtimeMedia",
    "UIBlur",
    "VelocityMotor",
    "VideoDeviceInput",
    "WrapTextureTransfer",
]


def load_dict(nest, nested_classes):
    for k, v in nest.items():
        if (
            k in blacklisted_branches
            or ("metadata" in k.lower())
            or "TweenBase" in k
            or ("mesh" in k.lower() and not "meshpart" in k.lower())
        ):
            continue
        nest_c = deepcopy(nested_classes)
        nest_c.append(nest[k]["superclass"])
        nest_c = list(set(nest_c))
        if any(item in nest[k]["tags"] for item in disallowed):
            for item in disallowed:
                if item in nest[k]["tags"]:
                    add_removed_item(removed_items["Classes"], k, item)
        elif (
            not any(item in k.lower() for item in blacklisted_names)
            and not k in blacklisted_classes
            and not k == "DebugClass"
        ):
            for name in nest[k]["properties"]:
                if not "Tags" in nest[k]["properties"][name]:
                    nest[k]["properties"][name] = {
                        "Category": nest[k]["properties"][name]["Category"],
                        "MemberType": nest[k]["properties"][name]["MemberType"],
                        "Tags": [],
                        "ValueType": nest[k]["properties"][name]["ValueType"],
                    }
            nest_c.sort()

            dict_list["Classes"][k] = {
                "Properties": nest[k]["properties"],
                "Tags": nest[k]["tags"],
                "Superclass": nest[k]["superclass"],
                "NestedClasses": nest_c,
            }

            if not nest[k]["superclass"] in superclasses:
                superclasses.append(nest[k]["superclass"])
        load_dict(nest[k], nest_c)


load_dict(
    final_dict["Classes"]["Instance"],
    [
        "Instance",
    ],
)

with open(script_dir + "/" + "intermediate_data5.json", "w") as file:
    json.dump(dict_list, file, indent=4)

for k, i in removed_items["Classes"].items():
    removed_items["Classes"][k] = list(set(i))


def load_enums(enum_list):
    for e in enum_list:
        if "Tags" in e.keys():
            if "Deprecated" in e["Tags"]:
                add_removed_item(removed_items["Enums"], e["Name"], "Deprecated")
                continue
        dict_list["Enums"][e["Name"]] = {}
        for enumeration in e["Items"]:
            if "Tags" in enumeration.keys():
                if "Deprecated" in enumeration["Tags"]:
                    add_removed_item(
                        removed_items["Enums"],
                        f"{e['Name']}.{enumeration['Name']}",
                        "Deprecated",
                    )
                    continue
            dict_list["Enums"][e["Name"]][enumeration["Name"]] = enumeration["Value"]


load_enums(enums)

for k, i in removed_items["Enums"].items():
    removed_items["Enums"][k] = list(set(i))

with open(script_dir + "/" + "removed.json", "w") as file:
    json.dump(removed_items, file, indent=4)

# print(superclasses)

# print(len(dict_list.keys()))

for k, i in dict_list["Classes"].items():
    for c in i["NestedClasses"]:
        if (
            c in dict_list["Classes"].keys()
            and not c in dict_list["Classes"][c]["NestedClasses"]
        ):
            dict_list["Classes"][c]["NestedClasses"].append(c)

superclass_structure = {}

for k, i in dict_list["Classes"].items():
    for c in i["NestedClasses"]:
        if c == "Instance":
            continue
        if not c in superclass_structure.keys():
            superclass_structure[c] = []
        superclass_structure[c].append(k)


superclass_structure = dict(reversed(superclass_structure.items()))

for c, i in superclass_structure.items():
    print(f"{c}:")
    i.sort()
    for o in i:
        print(f"    {o}")

value_types = []

most_properties = 0
class_with = None
unique_types = []
class_types = []
particle_emitter = [
    "ContentId",
    "Content",
    "String",
    "NumberRange",
    "Vector2",
    "Bool",
    "Int32",
    "Float32",
    "ColorSequence",
    "Vector3",
    "NumberSequence",
]


for k, i in dict_list["Classes"].items():
    for p in i["Properties"].values():
        if p["ValueType"]["Category"] != "Enum":
            value_types.append(p["ValueType"]["Name"])
            if not p["ValueType"]["Name"] in particle_emitter:
                unique_types.append(p["ValueType"]["Name"])
    if len(set(unique_types)) > most_properties:
        class_with = k
        most_properties = len(set(unique_types))
        class_types = set(unique_types)

    unique_types = []
value_types = list(set(value_types))
value_types.sort()
print(value_types)
print(len(value_types))

print(f"{class_with}: {most_properties}")
print(class_types)

with open(script_dir + "/" + "data.json", "w") as file:
    json.dump(dict_list, file, indent=4)
