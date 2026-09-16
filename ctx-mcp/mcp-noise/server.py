# noise: an MCP server whose only purpose is to carry a large `instructions`
# field into the Claude Code system prompt.
#
# One tool, and the shortest body a tool can have, so that the difference
# between this image and ctx-base cannot come from anywhere else: whatever
# `/context` fails to account for is the instructions and nothing but them.
#
# stdio rather than http: it starts with the agent, needs no network and no
# port, and a maintainer reproduces it with the two files of this directory.
# Written against the official Python SDK (`mcp`, pinned in the Dockerfile)
# rather than hand rolled over JSON-RPC, so that no one has to wonder
# whether the handshake is the part that misbehaves. MCPServer is what the
# 2.x SDK calls the class the 1.x one called FastMCP.
from pathlib import Path

from mcp.server.mcpserver import MCPServer

# Read next to this file, not from the working directory: Claude Code starts
# the server from wherever the agent happens to be.
INSTRUCTIONS = (Path(__file__).parent / "instructions.txt").read_text()

mcp = MCPServer("noise", instructions=INSTRUCTIONS)


@mcp.tool()
def ping() -> str:
    """Return pong."""
    return "pong"


mcp.run()
