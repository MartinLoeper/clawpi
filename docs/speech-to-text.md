# Speech-to-Text

## Overview

Audio transcription supports two backends:

1. **Groq cloud** (optional) — whisper-large-v3-turbo via Groq API, near-instant (~216x real-time), best accuracy
2. **Local whisper.cpp** (always available) — runs on-device, no internet needed

When Groq is enabled, it's tried first. If it fails (network error, missing key, API issue), the wrapper automatically falls back to local whisper.cpp. This gives you cloud-quality transcription with offline resilience.

```
Telegram voice message → Gateway downloads .ogg
  → [Groq enabled?] → curl to Groq API (sends .ogg directly) → text
  → [Groq failed or disabled] → ffmpeg converts to WAV → whisper-cli transcribes → text
  → text fed to agent
```

## Groq Cloud Transcription

### Quick Start

1. Get an API key from [console.groq.com/keys](https://console.groq.com/keys)
2. Provision on the Pi: `./scripts/provision-groq.sh [host]`
3. Enable in NixOS config:
   ```nix
   services.clawpi.audio.enable = true;
   services.clawpi.audio.groq.enable = true;
   ```
4. Deploy: `./scripts/deploy.sh [host] --specialisation kiosk`

### NixOS Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `services.clawpi.audio.groq.enable` | bool | `false` | Enable Groq cloud transcription with local fallback |
| `services.clawpi.audio.groq.apiKeyFile` | path | `/var/lib/clawpi/groq-api-key` | Path to the Groq API key file |
| `services.clawpi.audio.groq.model` | string | `"whisper-large-v3-turbo"` | Groq transcription model |

Groq supports .ogg/opus natively — no ffmpeg conversion needed. The API key is read at transcription time from the file, so you can rotate it without restarting the gateway.

## Local whisper.cpp

The gateway passes the audio file path via `{{MediaPath}}` template substitution in the args. The wrapper script handles backend selection, format conversion, and Eww overlay updates.

### NixOS Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `services.clawpi.audio.enable` | bool | `false` | Enable audio transcription |
| `services.clawpi.audio.model` | enum | `"tiny"` | Whisper model: `tiny`, `base`, `small` |
| `services.clawpi.audio.language` | string | `"auto"` | Language code or `"auto"` |
| `services.clawpi.audio.timeoutSeconds` | int | `60` | Transcription timeout |

### Whisper Model Comparison

All models use the same architecture, scaled by parameter count. We use the multilingual variants (`ggml-<model>.bin`) to support `auto` language detection. English-only variants (`.en`) exist for tiny/base/small and are slightly better for English-only use.

| Model | Params | Download | RPi 5 Speed | RAM | Notes |
|-------|--------|----------|-------------|-----|-------|
| **tiny** | 39M | 75 MB | ~0.3x real-time | ~1 GB | **Default.** Fastest, good for voice commands |
| **base** | 74M | 142 MB | ~0.7x real-time | ~1 GB | Best balance of speed and accuracy |
| **small** | 244M | 466 MB | ~2-3x real-time | ~2 GB | Better multilingual accuracy |
| medium | 769M | 1.5 GB | ~5x real-time | ~3 GB | High accuracy, too slow for interactive use |
| large-v3 | 1.5B | 2.9 GB | Impractical | ~5 GB | Best accuracy, won't fit comfortably on 8 GB Pi |
| large-v3-turbo | 809M | 1.5 GB | ~5x real-time | ~3 GB | Large-v3 quality at medium size, still slow on Pi |

**Why `tiny`:** Prioritizes low latency for interactive Telegram voice messages. `tiny` is ~3x faster than real-time on the RPi 5, which means near-instant transcription. All models are multilingual (using `ggml-<model>.bin` variants) so `auto` language detection works with any model. If accuracy is insufficient, switch to `base` — the biggest quality jump is tiny → base.

Only `tiny`, `base`, and `small` are currently packaged in `pkgs/whisper-model.nix`. The larger models are feasible on the Pi (8 GB RAM) but impractical for interactive Telegram voice messages where response latency matters.

### Gateway Config (injected via ExecStartPre)

The typed Nix config schema doesn't expose `tools.media.audio.models`, so the config is patched at service start via `jq`. See `docs/workarounds.md` for details.

```json
{
  "tools": {
    "media": {
      "audio": {
        "enabled": true,
        "language": "auto",
        "models": [
          {
            "type": "cli",
            "command": "/nix/store/...-whisper-transcribe",
            "args": ["{{MediaPath}}"],
            "timeoutSeconds": 60
          }
        ]
      }
    }
  }
}
```

### System Dependencies

When `audio.enable = true`, these packages are added:
- `whisper-cpp` — transcription engine
- `file` — MIME type detection (used by gateway)
- `ffmpeg-headless` — audio format conversion (Telegram sends .ogg/opus)
- `curl` — Groq API calls (only when `audio.groq.enable = true`)

### Files

- `modules/clawpi.nix` — NixOS options + system packages
- `home/openclaw.nix` — ExecStartPre config patch + whisper wrapper with Groq/local logic
- `pkgs/whisper-model.nix` — fetches GGML model from HuggingFace
- `overlays/clawpi.nix` — exposes `whisper-model` package
- `scripts/provision-groq.sh` — provisions Groq API key on the Pi
