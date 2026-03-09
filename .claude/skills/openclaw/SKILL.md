---
name: openclaw
description: Run OpenClaw CLI commands on the Pi to inspect the gateway, list plugins, check status, and debug issues. Use when the user asks about the gateway state, installed plugins, agent config, or needs to troubleshoot OpenClaw.
user-invocable: true
---

# OpenClaw Gateway CLI

Run OpenClaw CLI commands on the Pi to inspect and manage the gateway.

## Running commands on the Pi

All commands run as the `kiosk` user (which owns the gateway process):

```sh
ssh -i id_ed25519_rpi5 nixos@<host> "sudo -u kiosk XDG_RUNTIME_DIR=/run/user/\$(id -u kiosk) openclaw <command>"
```

Replace `<host>` with the Pi's address (e.g. `192.168.0.64` or `openclaw-rpi5.local`).

## Common commands

### List plugins

```sh
openclaw plugins list
```

Shows all discovered plugins, their load status, and source paths.

### Check gateway config

```sh
openclaw config get
```

Prints the current merged gateway configuration (JSON).

### Gateway doctor (health check)

```sh
openclaw doctor
```

Runs diagnostic checks and reports warnings (e.g. missing config, channel issues).

### List skills

```sh
openclaw skills list
```

Shows discovered skills and their status.

### Gateway status / version

```sh
openclaw version
```

### View gateway logs

Logs are written to a file, not journalctl:

```sh
ssh -i id_ed25519_rpi5 nixos@<host> "tail -100 /tmp/openclaw/openclaw-gateway.log"
```

Filter for specific events:

```sh
ssh -i id_ed25519_rpi5 nixos@<host> "grep -i 'error\|warn\|plugin' /tmp/openclaw/openclaw-gateway.log | tail -30"
```

### Restart the gateway

```sh
ssh -i id_ed25519_rpi5 nixos@<host> "sudo -u kiosk XDG_RUNTIME_DIR=/run/user/\$(id -u kiosk) systemctl --user restart openclaw-gateway.service"
```

### Check gateway service status

```sh
ssh -i id_ed25519_rpi5 nixos@<host> "sudo -u kiosk XDG_RUNTIME_DIR=/run/user/\$(id -u kiosk) systemctl --user status openclaw-gateway.service"
```

## Gateway config on the Pi

- **Config file:** `/var/lib/kiosk/.openclaw/openclaw.json` (managed by Home Manager, force-overwritten on activation)
- **Token:** `/var/lib/kiosk/.openclaw/gateway-token.env`
- **Agent auth:** `/var/lib/kiosk/.openclaw/agents/main/agent/auth-profiles.json`
- **Workspace:** `/var/lib/kiosk/.openclaw/workspace/`

To read config (requires root since kiosk home is restricted):

```sh
ssh -i id_ed25519_rpi5 nixos@<host> "sudo cat /var/lib/kiosk/.openclaw/openclaw.json"
```

## Send a message to the agent (CLI)

Run a single agent turn via the CLI. Useful for debugging — the `--json` output shows which tools were called, token usage, session ID, and the full agent response.

**Important:** The `OPENCLAW_GATEWAY_TOKEN` env var must be passed to authenticate with the running gateway. Read it from the token file on the Pi.

```sh
# On the Pi (via SSH):
TOKEN=$(sudo cat /var/lib/kiosk/.openclaw/gateway-token.env | grep -oP 'OPENCLAW_GATEWAY_TOKEN=\K.*')
sudo -u kiosk XDG_RUNTIME_DIR=/run/user/$(id -u kiosk) OPENCLAW_GATEWAY_TOKEN=$TOKEN \
  openclaw agent --agent main --message "your message here" --json
```

The `--json` response includes:
- `result.payloads[].text` — the agent's text response
- `result.meta.agentMeta.usage` — token usage (input, output, cache)
- `result.meta.agentMeta.model` — which model was used
- `result.meta.agentMeta.sessionId` — session ID for follow-up messages
- `result.meta.systemPromptReport.tools.entries` — all tools available to the agent with schema sizes

Without `--json`, only a one-word status (`completed`) is printed.

**Note:** This creates a standalone CLI session — the response is **not** delivered to Telegram or other channels. It's purely for debugging and testing tool invocations.

## Tool invoke HTTP API

Test registered plugin tools directly via the gateway's HTTP API:

```sh
# Get the gateway token
TOKEN=$(ssh -i id_ed25519_rpi5 nixos@<host> "sudo cat /var/lib/kiosk/.openclaw/gateway-token.env" | grep -oP 'OPENCLAW_GATEWAY_TOKEN=\K.*')

# Ensure SSH tunnel is open (port 18789)
ssh -i id_ed25519_rpi5 -L 18789:127.0.0.1:18789 -N -f nixos@<host>

# Invoke a tool
curl -s -X POST http://localhost:18789/tools/invoke \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool":"<tool_name>","input":{}}'
```

**Limitation:** The `/tools/invoke` HTTP API does **not** forward parameters to the tool's `execute()` function — params are always `{}`. This means only parameterless tools (e.g. `audio_status`, `audio_get_volume`) can be meaningfully tested via this endpoint. Tools with parameters (e.g. `audio_set_volume`) work correctly when invoked by the agent during a conversation.

## Troubleshooting

- **Plugin not loading:** Check `openclaw plugins list` — status should be `loaded`. If missing, verify `plugins.load.paths` in config points to the correct Nix store path.
- **Tool execution failed:** Check gateway logs for the specific error. Common issues: missing binaries in PATH, wrong `XDG_RUNTIME_DIR`, permission errors.
- **Config not updating:** Home Manager force-overwrites `openclaw.json` on activation, but the gateway may cache config. Restart the gateway after config changes.
