# openclaw-rpi-dashboards

NixOS configuration for Raspberry Pi 5, built on [nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi).

## Prerequisites

Your NixOS host needs aarch64 cross-compilation support:

```nix
boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```

## Initial Setup

### Build the SD image

```sh
./build.sh
```

### Flash to SD card

Use `flash-bmap.sh` (preferred) — it uses `bmaptool` which is significantly faster than a raw `dd`-style copy:

```sh
./flash-bmap.sh /dev/sdX
```

Alternatively, `flash.sh` uses [caligula](https://github.com/ifd3f/caligula) for an interactive flashing experience:

```sh
./flash.sh
```

### Boot the Pi

Insert the SD card and power on. The partition table expands automatically on first boot.

- **Hostname:** `openclaw-rpi5`
- **User:** `nixos` (wheel group, passwordless sudo)
- **SSH:** enabled, root login allowed

## Ongoing Deploys

After the initial flash, update the running Pi remotely via `nixos-rebuild`:

```sh
./deploy.sh                       # deploys to openclaw-rpi5.local (mDNS)
./deploy.sh 192.168.1.42          # deploys to a specific IP
./deploy.sh myhost -- --dry-run   # pass extra nixos-rebuild flags
```

This builds the system locally and copies the closure to the Pi over SSH. The generational bootloader (`"kernel"`) supports rollback to previous configurations.

## Flake Structure

| Config | Builder | Purpose |
|--------|---------|---------|
| `nixosConfigurations.rpi5` | `nixosSystemFull` | Remote deploys via `nixos-rebuild` |
| `nixosConfigurations.rpi5-installer` | `nixosInstaller` | Flashable SD card images |

Both share the same system configuration. `nixosSystemFull` includes RPi-optimized package overlays (FFmpeg, Kodi, VLC, libcamera, etc.) globally.
