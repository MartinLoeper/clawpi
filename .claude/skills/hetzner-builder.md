# Hetzner ARM Builder

Spin up a native aarch64 build server on Hetzner Cloud to avoid slow cross-compilation from x86_64.

## When to use

- Building the NixOS configuration takes too long locally (cross-compiling aarch64 on x86_64)
- Packages aren't in the binary cache (e.g. from a different nixpkgs revision)
- You need a native ARM build for testing

## Create the server

```sh
hcloud server create \
  --name openclaw-builder \
  --type cax21 \
  --image ubuntu-24.04 \
  --location nbg1 \
  --ssh-key "<your-ssh-key-name>"
```

Server types for ARM (`cax` series):

| Type | vCPUs | RAM | Disk | Use case |
|------|-------|-----|------|----------|
| cax11 | 2 | 4 GB | 40 GB | Light builds |
| **cax21** | **4** | **8 GB** | **80 GB** | **Recommended for this project** |
| cax31 | 8 | 16 GB | 160 GB | Parallel builds |
| cax41 | 16 | 32 GB | 320 GB | Heavy builds |

## Set up the server

After the server is created, SSH in and install Nix:

```sh
# 1. Install Nix with daemon mode
ssh root@<server-ip> "curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes"

# 2. Enable flakes
ssh root@<server-ip> "bash -lc 'mkdir -p ~/.config/nix && echo \"experimental-features = nix-command flakes\" > ~/.config/nix/nix.conf'"

# 3. Clone the repo and build
ssh root@<server-ip> "bash -lc 'git clone https://github.com/MartinLoeper/openclaw-rpi-dashboards.git && cd openclaw-rpi-dashboards && nix build .#nixosConfigurations.rpi5.config.system.build.toplevel -L'"
```

## Copy the build result to the Pi

After building on the server, copy the closure to the Pi:

```sh
# From the build server, copy to Pi
nix-copy-closure --to nixos@<pi-host> $(readlink -f result)

# Then activate on the Pi
ssh nixos@<pi-host> sudo $(readlink -f result)/bin/switch-to-configuration switch
```

Alternatively, use the build server as a Nix remote builder (add to `/etc/nix/machines`).

## Tear down

Don't forget to delete the server when done:

```sh
hcloud server delete openclaw-builder
```

Hetzner bills by the hour, so delete promptly after use.

## Why this exists

The project uses two different nixpkgs revisions:
- `nixos-raspberrypi` uses a custom nixpkgs fork (with RPi-specific patches)
- `nix-openclaw` uses stock NixOS nixpkgs

Packages from `nix-openclaw`'s nixpkgs (like jemalloc, Node.js dependencies) aren't in the RPi binary cache, so they get built from source. On x86_64, this means slow cross-compilation under QEMU. On a native aarch64 server, these builds run at full speed.
