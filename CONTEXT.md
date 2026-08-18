# Agent Configuration Architecture

The ubiquitous language for how this repository manages agent instructions and agent configuration across all installed coding agents.

## Language

**Shared Core**:
The single agent-agnostic instruction file that every installed agent reads.
_Avoid_: global AGENTS.md, shared instructions, instruction core

**Tool Layer**:
An instruction file that exactly one agent reads, holding only what that agent needs beyond the Shared Core.
_Avoid_: extension file, sidecar, per-tool tweaks

**Managed Dotfile**:
A file this repository owns and links into the home directory, so a new Mac reproduces it.
_Avoid_: tracked config, symlinked file

**Machine State**:
A file that stays outside the repository because the tool rewrites it at runtime or it holds credentials.
_Avoid_: local state, unmanaged config, local override

**Compat Path**:
Another agent's instruction file that Grok Build also reads and obeys.
_Avoid_: leak, cross-read
