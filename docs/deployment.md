# Deployment

## Deploy Command

```sh
./scripts/deploy.sh [host] [--specialisation kiosk]
```

- **Default host:** `openclaw-rpi5.local` (mDNS)
- **SSH user:** `nixos`
- **SSH key:** `id_ed25519_rpi5` in repo root (set up via `./scripts/setup-ssh.sh`)

The script builds the NixOS closure locally (cross-compiled for aarch64 on x86_64 hosts) and copies it to the Pi over SSH.

## Remote Build Cache (Hetzner ARM)

To avoid slow cross-compilation on x86_64, you can offload builds to a native aarch64 Hetzner Cloud server:

```sh
REMOTE_CACHE=<server-ip> ./scripts/deploy.sh openclaw-rpi5.local --specialisation kiosk
```

For SD image builds, build on the Hetzner server first, then `nix copy` the result locally. See the `hetzner-builder` skill for automating server provisioning.

## Specialisation Switching

The system supports NixOS specialisations. In the current compatibility mode, the base system also includes the kiosk graphical services (greetd + labwc + Chromium) so greetd starts reliably at boot. A runtime `kiosk` specialisation is still exposed for deployment and activation compatibility, so `--specialisation kiosk` should resolve instead of failing with `specialisation not found`.

### Activate kiosk mode (runtime)

```sh
ssh nixos@<host> "sudo \$(readlink -f /nix/var/nix/profiles/system)/specialisation/kiosk/bin/switch-to-configuration switch"
```

### Return to base mode (runtime)

```sh
ssh nixos@<host> sudo /run/current-system/bin/switch-to-configuration switch
```

Note: base mode currently still includes the kiosk graphical services for reliability; it is not a strict CLI-only mode under compatibility mode.

### Known Issue: Specialisation Not Activating on Deploy

`nixos-rebuild --specialisation kiosk` doesn't always activate the specialisation. After deploying, verify and manually activate if needed:

```sh
# Check which system is active (base vs kiosk)
readlink /run/current-system

# If the graphical login is not running, inspect greetd:
ssh nixos@<host> sudo systemctl status greetd

# Manually activate the kiosk specialisation:
ssh nixos@<host> "sudo \$(readlink -f /nix/var/nix/profiles/system)/specialisation/kiosk/bin/switch-to-configuration switch"

# Then restart greetd if needed:
ssh nixos@<host> sudo systemctl restart greetd

# Verify openclaw-gateway is running (may need manual start after spec switch):
ssh nixos@<host> "sudo -u kiosk XDG_RUNTIME_DIR=/run/user/\$(id -u kiosk) systemctl --user start openclaw-gateway"
```

## Port Forwarding

Access the gateway from your workstation via SSH tunnel:

```sh
ssh -i id_ed25519_rpi5 -L 18789:127.0.0.1:18789 -N nixos@<host>
```

Then open `http://localhost:18789` locally.

## PinchChat (Web UI)

[PinchChat](https://github.com/MarlBurroW/pinchchat) is a webchat UI for interacting with the OpenClaw gateway from your workstation.

```sh
# 1. Set up SSH tunnel to the gateway (see above)

# 2. Run PinchChat
./scripts/pinchchat.sh

# 3. Open http://localhost:3000 and enter the gateway token
```

Retrieve the token with `./scripts/gateway-token.sh`.
