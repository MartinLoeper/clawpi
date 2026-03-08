# OpenClaw Gateway Integration

## Overview

The OpenClaw gateway runs as a Home Manager user service for the `kiosk` user, managed via the [nix-openclaw](https://github.com/MartinLoeper/nix-openclaw) flake's Home Manager module (`programs.openclaw`).

## Flake Integration

The `nix-openclaw` flake provides:
- **Overlay** — builds the `openclaw-gateway` package (with a pnpm dependency fix)
- **Home Manager module** — manages config, systemd user service, and workspace for the `kiosk` user

```nix
# flake.nix (simplified)
inputs.nix-openclaw.url = "github:MartinLoeper/nix-openclaw/main";
inputs.home-manager.url = "github:nix-community/home-manager";

home-manager.users.kiosk = {
  imports = [ nix-openclaw.homeManagerModules.openclaw ];
  programs.openclaw = {
    enable = true;
    config.gateway.mode = "local";
  };
};
```

## Service Details

| Property | Value |
|----------|-------|
| Service name | `openclaw-gateway.service` (systemd user service, kiosk user) |
| Port | `18789` |
| Config | `~/.openclaw/openclaw.json` (managed by Home Manager) |
| State directory | `/var/lib/kiosk/.openclaw` |
| User | `kiosk` (system user) |
| Gateway mode | `local` (loopback only) |

## Authentication

A random gateway token is generated on first boot by a companion user service (`openclaw-gateway-token.service`). The token is stored at `~/.openclaw/gateway-token.env` and loaded via `EnvironmentFile`.

### Retrieving the Token

```sh
./scripts/gateway-token.sh [host]
```

Defaults to `openclaw-rpi5.local`. Pass an IP to override:

```sh
./scripts/gateway-token.sh 192.168.0.64
```

The script prints the token and a ready-to-use dashboard URL with the token parameter.

## Kiosk Connection

The kiosk specialisation runs Cage + Chromium pointing at `http://localhost:18789`. The Cage service waits for PipeWire before launching Chromium so that audio is available.

## Useful Commands

```sh
# Check service status (run as kiosk user)
ssh nixos@openclaw-rpi5.local sudo -u kiosk XDG_RUNTIME_DIR=/run/user/\$(id -u kiosk) systemctl --user status openclaw-gateway

# View logs
ssh nixos@openclaw-rpi5.local cat /tmp/openclaw/openclaw-gateway.log

# Retrieve the gateway token
./scripts/gateway-token.sh
```
