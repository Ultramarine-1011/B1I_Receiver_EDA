"""Write a wire-only bank using the verified mapped channel's actual ports."""
from __future__ import print_function
import re
import sys

netlist, output, reference = sys.argv[1:]
name = "tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1"
with open(netlist) as stream:
    data = stream.read()
match = re.search(r"(?ms)^[ \t]*module[ \t]+" + name + r"\s*\(.*?^[ \t]*endmodule\b", data)
if match is None:
    raise ValueError("Mapped channel declaration is absent")
ports = []
for direction, width, names in re.findall(r"(?m)^\s*(input|output)\s+(?:wire\s+|signed\s+|reg\s+)*(\[\s*\d+\s*:\s*\d+\s*\]\s*)?([^;]+);", match.group()):
    for port in names.split(","):
        port = port.strip()
        if not re.match(r"^[A-Za-z_$][\w$]*$", port):
            raise ValueError("Unsupported mapped port declaration: " + port)
        ports.append((direction, width, port))
bits = 0
for _, width, _ in ports:
    limits = re.findall(r"\d+", width)
    bits += abs(int(limits[0]) - int(limits[1])) + 1 if limits else 1
if bits != 1139 or not set(port for _, _, port in ports).issuperset(set(["clk", "reset_n"])):
    raise ValueError("Mapped channel interface differs from the verified 1139-bit interface")
declarations = ["input clk", "input reset_n"]
for channel in range(6):
    for direction, width, port in ports:
        if port not in ("clk", "reset_n"):
            declarations.append("%s %sc%d_%s" % (direction, width, channel, port))
lines = ["// Six mapped tracking channels, independent data/configuration ports.",
         "// Scope excludes acquisition, receiver management, navigation and PAD.",
         "module tracking_bank6 (", "    " + ",\n    ".join(declarations), ");"]
for channel in range(6):
    lines.append("    %s channel%d (" % (reference, channel))
    connections = []
    for _, _, port in ports:
        signal = port if port in ("clk", "reset_n") else "c%d_%s" % (channel, port)
        connections.append(".%s(%s)" % (port, signal))
    lines.append("        " + ",\n        ".join(connections) + ");")
lines.append("endmodule\n")
with open(output, "w") as stream:
    stream.write("\n".join(lines))
print("TRACKING_BANK_WRAPPER_PASS ports=%d bits=%d channels=6" % (len(ports), bits))
