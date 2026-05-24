---
name: openclaw
description: Run OpenClaw CLI commands on the Pi to inspect the gateway, list plugins, check status, and debug issues. Use when the user asks about the gateway state, installed plugins, agent config, or needs to troubleshoot OpenClaw.
user-invocable: true
---

# OpenClaw Gateway CLI

Run OpenClaw CLI commands on the Pi to inspect and manage the gateway.

Current ClawPi `rpi4-telegram` target details:

- Host: `nixos@192.168.36.113`
- Key: `/home/afk/Documents/projects/clawpi/id_ed25519_rpi4`
- Gateway: OpenClaw `2026.5.20`
- Config mode: `OPENCLAW_NIX_MODE=1` (OpenClaw must not mutate config)

For probes/deploys, prefer `-o UserKnownHostsFile=/dev/null` to avoid polluting known_hosts.

## Updating OpenClaw on `rpi4-telegram`

Use this checklist when updating OpenClaw or `nix-openclaw` in a fresh session.

Baseline before the next update:

- OpenClaw version: `2026.5.20`
- OpenClaw upstream commit: `e510042870cf248c0e0461b6f8d427326266141d`
- OpenClaw source hash used during the last update: `sha256-xMSuPM71t166k6wfqeJ07JBUuvzCtbYUMpyEZ8OGK9s=`
- `nix-openclaw` rev: `4c85a78238deb39b70bc1e408dd8d5bce804e38a`
- Last known-good deployed system: `/nix/store/0f9ddmlw0376wvlzsxfhxr21pdc5k5sx-nixos-system-openclaw-rpi4-25.11.20260223.2597cb7`

Preferred update strategy:

1. Prefer updating/pinning `nix-openclaw` over carrying a local OpenClaw source override.
2. Do not deploy `rpi4-telegram` with `--specialisation kiosk`; it is a flake configuration, not a runtime specialisation.
3. Keep fixes in Nix source or runtime patch scripts; do not rely on `openclaw doctor --fix` because Nix mode blocks config mutation.
4. If new files are added and a Nix command will reference them, `git add` them first so the flake can see them.

Build on the Coder/Hetzner ARM builder, not by slow local cross-compilation:

```sh
rsync -az --delete --exclude .git --exclude result --exclude .pi/deploy-logs --exclude .pi/schedule-prompts.json \
  ./ dev.hetzner-builder.afkdev8.coder:/workspaces/clawpi/

ssh dev.hetzner-builder.afkdev8.coder \
  'cd /workspaces/clawpi && nix build .#nixosConfigurations.rpi4-telegram.config.system.build.toplevel --accept-flake-config --show-trace -L --max-jobs 1 --cores 1 --print-out-paths'
```

Deploy from the builder to the Pi with `nix-copy-closure` and exported `NIX_SSHOPTS`:

```sh
SYSTEM=/nix/store/...-nixos-system-openclaw-rpi4-...
ssh dev.hetzner-builder.afkdev8.coder \
  "cd /workspaces/clawpi && export NIX_SSHOPTS='-i /workspaces/clawpi/id_ed25519_rpi4 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=120 -o ServerAliveInterval=30 -o ServerAliveCountMax=20' && nix-copy-closure --to nixos@192.168.36.113 '$SYSTEM'"

ssh -i /home/afk/Documents/projects/clawpi/id_ed25519_rpi4 \
  -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  nixos@192.168.36.113 \
  "sudo nix-env -p /nix/var/nix/profiles/system --set '$SYSTEM' && sudo '$SYSTEM/bin/switch-to-configuration' switch"
```

After every OpenClaw update/deploy, verify:

```sh
ssh -i /home/afk/Documents/projects/clawpi/id_ed25519_rpi4 \
  -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  nixos@192.168.36.113 '
    uid=$(id -u kiosk)
    export XDG_RUNTIME_DIR=/run/user/$uid
    export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus
    echo SYSTEM=$(readlink -f /run/current-system)
    openclaw --version
    sudo -u kiosk XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS openclaw config validate
    sudo -u kiosk XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS systemctl --user --no-pager --plain is-active openclaw-gateway.service openclaw-gateway-start.service
    sudo jq -c "{model:.agents.defaults.model,telegram:.channels.telegram,plugins:.plugins.entries,bundledDiscovery:.plugins.bundledDiscovery,browser:.browser.enabled}" /var/lib/kiosk/.openclaw/openclaw.json
    sudo tail -260 /tmp/openclaw/openclaw-gateway.log | grep -Ei "telegram|provider|gateway|ready|listening|NixMode|invalid|error|failed|auto-enabled|openai-codex|model-fallback|sendMessage|Inbound" | tail -160
  '
```

Expected post-update state:

- `openclaw config validate` succeeds.
- `openclaw-gateway.service` and `openclaw-gateway-start.service` are active.
- Gateway log reaches `http server listening` and `gateway ready`.
- Telegram plugin is loaded; recent working baseline showed `3 plugins: browser, memory-core, telegram`.
- Telegram logs show provider startup and message flow, e.g. `starting provider (@werner_clawpi_bot)`, `Inbound message`, and `sendMessage ok`.
- Runtime config keeps the values listed in the Gateway config section below.

Known non-blocking noise:

- `avahi-daemon.service` may fail with `Failed to create PID file: File exists`; this has been unrelated to OpenClaw/Telegram health.
- The Pi may be slow after deploys; SSH can time out during banner exchange. Retry with longer `ConnectTimeout` before assuming failure.
- Workspace startup script noise from Coder is unrelated to the build if the Nix build completes.

## Running commands on the Pi

All commands run as the `kiosk` user (which owns the gateway process):

```sh
ssh -i id_ed25519_rpi5 nixos@<host> "sudo -u kiosk XDG_RUNTIME_DIR=/run/user/\$(id -u kiosk) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/\$(id -u kiosk)/bus openclaw <command>"
```

For the Pi 4 Telegram target:

```sh
ssh -i /home/afk/Documents/projects/clawpi/id_ed25519_rpi4 \
  -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  nixos@192.168.36.113 \
  'uid=$(id -u kiosk); sudo -u kiosk XDG_RUNTIME_DIR=/run/user/$uid DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus openclaw <command>'
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
openclaw config validate
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

OpenClaw runs in Nix mode on ClawPi:

- `OPENCLAW_NIX_MODE=1`
- `openclaw doctor --fix` cannot mutate `openclaw.json`
- fixes must be made in Nix source or in ClawPi's `ExecStartPre`/Home Manager activation JSON patch scripts
- Home Manager activation rewrites `openclaw.json`, so runtime JSON patches that must survive deploys need to run during activation as well as before gateway start

To read the most important runtime config values (requires root since kiosk home is restricted):

```sh
ssh -i id_ed25519_rpi5 nixos@<host> \
  'sudo jq -c "{model:.agents.defaults.model,models:.agents.defaults.models,telegram:.channels.telegram,plugins:.plugins,browser:.browser.enabled}" /var/lib/kiosk/.openclaw/openclaw.json'
```

Expected for `rpi4-telegram` after activation:

- `.agents.defaults.model.primary = "github-copilot/gpt-5.3-codex"`
- `.plugins.entries.github-copilot.enabled = true`
- `.plugins.entries.browser.enabled = true`
- `.plugins.bundledDiscovery = "compat"`
- `.channels.telegram.enabled = true`
- `.channels.telegram.streaming` is an object with `mode = "block"`, not scalar `"block"`

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
- **Config not updating:** Home Manager force-overwrites `openclaw.json` on activation. Put critical runtime patches in `home.activation.patchOpenClawRuntimeConfig` and `ExecStartPre`, then restart or let hot reload apply.
- **`NixModeConfigMutationError`:** OpenClaw tried to auto-enable or mutate config while `OPENCLAW_NIX_MODE=1`. Explicitly set inferred entries in Nix, e.g. `plugins.entries.github-copilot.enabled = true`, `plugins.entries.browser.enabled = true`, `channels.telegram.enabled = true`, and `plugins.bundledDiscovery = "compat"`.
- **Missing API key for provider `openai-codex`:** Check runtime config first. If `.agents.defaults.model.primary` is missing, OpenClaw fell back to an OpenAI Codex model. Ensure the models patch runs during Home Manager activation and verify `github-copilot/gpt-5.3-codex` is the primary model.
- **Telegram streaming validation errors:** OpenClaw `2026.5.20` expects object-shaped `channels.telegram.streaming`; ClawPi translates legacy Nix options in `home/openclaw.nix` via `patch-openclaw-telegram-streaming`.
