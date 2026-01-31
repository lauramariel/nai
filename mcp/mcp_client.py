# Lightweight MCP Client to list tools from MCP server

import subprocess
import json
import time
import sys

MCP_SERVER_FQDN="mcp-server.example.org"
MCP_URL = f"https://{MCP_SERVER_FQDN}/mcp"

proc = subprocess.Popen(
    ["npx", "-y", "mcp-remote", MCP_URL],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=sys.stderr,
    text=True,
    bufsize=1,
)

def send(msg):
    proc.stdin.write(json.dumps(msg) + "\n")
    proc.stdin.flush()

def recv():
    line = proc.stdout.readline()
    if not line:
        return None
    return json.loads(line)

# Give MCP time to initialize
time.sleep(0.5)

# Request tool list
send({
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
})

resp = recv()

print("\n=== Available Tools ===\n")

for tool in resp["result"]["tools"]:
    print(f"Tool: {tool['name']}")
    print(f"Description: {tool.get('description', '')}")
    print("Input schema:")
    print(json.dumps(tool["inputSchema"], indent=2))
    print("-" * 40)

proc.terminate()
