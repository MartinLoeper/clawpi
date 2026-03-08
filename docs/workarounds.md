# Workarounds

## Use `nixosSystem` instead of `nixosSystemFull`

**Added:** 2026-03-07

The `nixos-raspberrypi` flake provides two builders: `nixosSystem` (base) and `nixosSystemFull`. The "Full" variant applies `overlays.pkgs` globally, which includes RPi-optimized builds of FFmpeg, pipewire, and other multimedia packages. This causes a massive rebuild cascade — Chromium, for example, gets rebuilt from source under QEMU emulation because its transitive dependencies (FFmpeg, etc.) are patched.

Since we only run Chromium in kiosk mode pointing at `localhost:18789`, we don't need RPi-optimized multimedia codecs. Switching to `nixosSystem` keeps stock nixpkgs packages (fully cached on `cache.nixos.org`) while still providing RPi kernel, firmware, and vendor packages via `pkgs.rpi`.

The same applies to the installer: `nixosInstaller` hardcodes `full-nixos-raspberrypi-config`, so we construct the installer manually from `nixosSystem` + the sd-image module.

**Impact:** Build time drops from hours (QEMU-emulated Chromium compilation) to minutes (everything from cache).

**Re-evaluate:** If we later need RPi-optimized multimedia (e.g. hardware-accelerated video playback), we can selectively add individual overlays from `nixos-raspberrypi` instead of the full set.

## SDL3: Disable test suite (`doCheck = false`)

**Added:** 2026-03-07

The `sdl3` package's test suite fails inside the Nix build sandbox. Specifically, `process_testNonExistingExecutable` fails because process spawning behaves differently in the sandboxed environment.

Since `sdl3` is a transitive dependency of Chromium (via `sdl2-compat` → `ffmpeg-rpi` → `chromium`), this single test failure cascades and breaks the entire system build.

**Fix:** An overlay in `flake.nix` disables the SDL3 test suite:

```nix
(final: prev: {
  sdl3 = prev.sdl3.overrideAttrs (old: {
    doCheck = false;
  });
})
```

**Upstream:** This is a nixpkgs issue — the test should be skipped in sandbox builds. Re-evaluate on nixpkgs updates and remove this overlay once the upstream fix lands.
