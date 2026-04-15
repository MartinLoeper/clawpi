---
name: speak
description: Speak text aloud through the kiosk speakers using TTS. Use when the user wants you to say something out loud, answer verbally, or introduce yourself audibly.
version: 1.0.0
triggers:
  - "sag"
  - "sprich"
  - "speak"
  - "say"
  - "laut"
  - "out loud"
  - "stell dich vor"
  - "introduce yourself"
---

# Speak Aloud

The user wants audible speech output. Follow the "Tool Execution" rules from AGENTS.md — every step below must be a real structured tool call.

## Steps

1. Call `tts_cartesia` with the text to speak.
2. Call `audio_play` with the file path from the result.
3. Briefly confirm what you said. Keep it short.
