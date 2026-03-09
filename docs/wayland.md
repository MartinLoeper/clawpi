# Wayland Compositor: Cage → labwc Migration

## Decision

Replace **Cage** with **labwc** as the Wayland compositor for the kiosk specialisation. This enables **Eww** (ElKowars Wacky Widgets) overlay widgets on top of the fullscreen Chromium dashboard.

## Why Migrate?

Cage is a single-application kiosk compositor that intentionally omits the **wlr-layer-shell** protocol. Eww requires wlr-layer-shell to render overlay widgets (status bars, system monitors, notification panels) on Wayland. Without it, Eww windows are treated as regular toplevels and cannot float above or anchor to screen edges alongside the fullscreen browser.

## Why labwc?

### Candidates Evaluated

| Compositor | Layer-Shell | Pi 5 Ready | Kiosk Ease | Weight | nixpkgs |
|------------|:-----------:|:----------:|:----------:|:------:|:-------:|
| **labwc** | Yes | Excellent | Excellent | Lightest | Yes |
| Sway | Yes | Good | Good | Light | Yes |
| River | Yes | Unproven | Fair | Light | Yes |
| Niri | Yes | Unproven | Fair | Light | Yes |
| dwl | Yes | Unproven | Poor | Lightest | Yes |
| Hyprland | Yes | Poor | Fair | Heavy | Yes |
| Gamescope | Partial | Broken | N/A | N/A | Yes |

### labwc Wins Because

1. **Official Pi compositor.** Raspberry Pi OS switched from Wayfire to labwc as its default compositor in October 2024. It is tested and maintained specifically for Pi hardware.
2. **Lightest wlroots-based option** with full layer-shell support. Stacking compositor inspired by Openbox — no tiling, no animations, no effects by default.
3. **Kiosk-ready configuration.** Supports `autostart` scripts, `rc.xml` window rules for fullscreen/no-decorations, and a `HideCursor` action — everything Cage provided, plus more.
4. **wlr-layer-shell support.** Eww widgets can anchor to screen edges and render in overlay layers above the fullscreen Chromium window.

### Why Not Sway?

Sway is the strongest alternative. It has mature layer-shell support and powerful IPC scripting via `swaymsg`. However, it is a full tiling window manager with workspaces, an IPC socket, and a config parser — features that add overhead without value in a single-app kiosk. labwc is simpler and lighter for this use case.

### Why Not Hyprland?

Too heavy (~1 GB RAM typical). Animations and Vulkan-based effects compete with Chromium for GPU resources. Reports of poor performance on Pi 5 at 1080p. Not designed for embedded/kiosk use.

### Why Not Gamescope?

Broken on Pi 5. The VideoCore VII GPU lacks the Vulkan features Gamescope requires (`vkCreateDevice` failures). Designed for game compositing on x86/Steam Deck, not web kiosk.

## Architecture After Migration

```
┌──────────────────────────────────────────┐
│            Raspberry Pi 5                │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │            labwc                   │  │
│  │          (Wayland)                 │  │
│  │                                    │  │
│  │  ┌──────────────┐  ┌───────────┐  │  │
│  │  │  Chromium    │  │    Eww    │  │  │
│  │  │ (fullscreen) │  │ (overlay) │  │  │
│  │  └──────┬───────┘  └───────────┘  │  │
│  └─────────┼──────────────────────────┘  │
│            │                             │
│     localhost:18789                      │
│            │                             │
│   ┌────────▼────────┐                    │
│   │    OpenClaw     │                    │
│   │    Gateway      │                    │
│   └─────────────────┘                    │
└──────────────────────────────────────────┘
```

## labwc Kiosk Configuration

labwc uses three config files in `~/.config/labwc/`:

### `autostart`

```sh
# Launch Chromium fullscreen
chromium --kiosk --no-first-run --disable-pinch http://localhost:18789 &

# Launch Eww widgets
eww open-many <widget-names> &
```

### `rc.xml`

```xml
<labwc_config>
  <windowRules>
    <!-- Chromium: fullscreen, no decorations -->
    <windowRule identifier="chromium" matchOnce="true">
      <action name="Maximize" />
      <action name="ToggleDecoration" />
    </windowRule>
  </windowRules>
</labwc_config>
```

### `environment`

```sh
# Disable cursor for touch-only kiosk
XCURSOR_SIZE=0
```

## Migration Steps

1. Replace `cage` with `labwc` in `modules/kiosk.nix`
2. Add labwc config files (`autostart`, `rc.xml`) via Home Manager or NixOS config
3. Add `eww` package to the kiosk closure
4. Create Eww widget configs for desired dashboard overlays
5. Update `docs/canvas.md` to reflect the new compositor
6. Update `docs/vision.md` architecture diagram

## References

- [labwc GitHub](https://github.com/labwc/labwc)
- [labwc config docs](https://labwc.github.io/labwc-config.5.html)
- [RPi OS switch to labwc (Hackaday)](https://hackaday.com/2024/10/28/raspberry-pi-oss-wayland-transition-completed-with-switch-to-labwc/)
- [Eww GitHub](https://github.com/elkowar/eww)
- [wlr-layer-shell protocol](https://wayland.app/protocols/wlr-layer-shell-unstable-v1)
