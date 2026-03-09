# Canvas: Kiosk Display for ClawPi

## Decision

Use **Cage** (Wayland kiosk compositor) + **Chromium** in `--kiosk` mode as the graphical display stack, delivered as a NixOS **specialisation** so the base system remains CLI-only.

## Why Cage + Chromium?

- **Cage** is a single-application Wayland compositor purpose-built for kiosk use. It launches one app fullscreen with no window chrome, no task switching, and no user escape — exactly what a dashboard display needs.
- **Chromium** renders any web content OpenClaw serves (dashboards, status pages, admin UIs). The `--kiosk` flag hides all browser UI. Additional flags disable first-run dialogs, crash bubbles, and pinch-to-zoom for a clean touch-friendly experience.
- Together they provide a minimal, robust display pipeline: kernel DRM → Wayland (Cage) → Chromium → web content at `http://localhost`.

## Why a Specialisation?

NixOS specialisations create alternative system profiles that share the same base closure but layer additional configuration on top. This gives us:

- **CLI by default** — the base system boots to a console, keeping the image small and SSH-friendly for headless operation.
- **Kiosk on demand** — the graphical stack is only activated when explicitly switched to, avoiding wasted resources when no display is attached.
- **Atomic switching** — `switch-to-configuration switch` transitions between CLI and kiosk without a reboot.
- **Shared closure** — both profiles share the same Nix store paths, so deploying the kiosk specialisation adds only the Cage/Chromium delta to the system.

## How to Switch

### Activate kiosk mode (runtime)

```sh
sudo /run/current-system/specialisation/kiosk/bin/switch-to-configuration switch
```

### Return to CLI mode (runtime)

```sh
sudo /run/current-system/bin/switch-to-configuration switch
```

### Deploy directly into kiosk mode

```sh
./scripts/deploy.sh -- --specialisation kiosk
```

## Bigger Picture

OpenClaw will serve dashboard web applications on `http://localhost`. The kiosk specialisation turns a Raspberry Pi 5 into a plug-and-play display appliance: power on, auto-login the `kiosk` user, launch Cage + Chromium, and render whatever OpenClaw is serving — no manual interaction required.
