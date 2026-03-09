# Speech-to-Text

## Current Implementation (whisper.cpp)

Local audio transcription using [whisper.cpp](https://github.com/ggerganov/whisper.cpp) on the Pi. The gateway invokes whisper-cli as an external command via the `audio.transcription.command` config.

### How It Works

```
Telegram voice message → Gateway downloads audio → whisper-cli transcribes → text returned to agent
```

### NixOS Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `services.clawpi.audio.enable` | bool | `false` | Enable audio transcription |
| `services.clawpi.audio.model` | enum | `"base"` | Whisper model: `tiny`, `base`, `small` |
| `services.clawpi.audio.language` | string | `"auto"` | Language code or `"auto"` |
| `services.clawpi.audio.timeoutSeconds` | int | `60` | Transcription timeout |

### Model Sizes (RPi 5)

| Model | Speed | RAM | Use case |
|-------|-------|-----|----------|
| `tiny` | ~0.3x real-time | ~1GB | Short commands |
| `base` | ~0.7x real-time | ~1GB | Commands + sentences (default) |
| `small` | ~2-3x real-time | ~2GB | Best accuracy, slow |

### Gateway Config (generated)

```json
{
  "audio": {
    "transcription": {
      "command": ["whisper-cli", "-m", "/nix/store/...-ggml-base.bin", "-l", "auto", "-np", "--no-gpu"],
      "timeoutSeconds": 60
    }
  }
}
```

### Files

- `modules/clawpi.nix` — NixOS options + whisper-cpp system package
- `home/openclaw.nix` — wires `audio.transcription` into gateway config
- `pkgs/whisper-model.nix` — fetches GGML model from HuggingFace
- `overlays/clawpi.nix` — exposes `whisper-model` package

## Future: Groq Cloud Transcription

The pinned OpenClaw version (schema rev `addd290f`) does not support provider-based `tools.media.audio.models` config. Once updated, Groq's Whisper API could replace local transcription for faster results:

```json
{
  "tools": {
    "media": {
      "audio": {
        "enabled": true,
        "models": [{ "provider": "groq", "model": "whisper-large-v3", "keyFile": "/var/lib/clawpi/groq-api-key" }]
      }
    }
  }
}
```

A Groq API key is already provisioned on the Pi at `/var/lib/clawpi/groq-api-key`.
