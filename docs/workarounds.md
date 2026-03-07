# Workarounds

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
