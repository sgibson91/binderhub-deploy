import json

file = "config.json"
config = json.load(open(file, "r"))

print(config["azure"]["subscription"], config["azure"]["res_grp_name"],
      config["azure"]["location"], config["azure"]["cluster_name"],
      config["azure"]["node_count"], config["azure"]["vm_size"])
