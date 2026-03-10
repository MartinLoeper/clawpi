#!/usr/bin/env bash
# Resume training from Step 2 (clips already generated).
# Run inside the training devShell.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

CONFIG="hey_claw.yml"
TRAIN="openwakeword/openwakeword/train.py"
LOG="$SCRIPT_DIR/training.log"

PIP_SITE="$SCRIPT_DIR/.pip/lib/python3.*/site-packages"
# shellcheck disable=SC2086
export PYTHONPATH="$SCRIPT_DIR/openwakeword:$SCRIPT_DIR/piper-sample-generator:$(echo $PIP_SITE):${PYTHONPATH:-}"
# Force soundfile backend (torchcodec not available with ROCm)
export TORCHAUDIO_BACKEND=soundfile

echo "=== Step 2/3: Augmenting clips ===" | tee -a "$LOG"
python3 "$TRAIN" --training_config "$CONFIG" --augment_clips 2>&1 | tee -a "$LOG"

echo "" | tee -a "$LOG"
echo "=== Step 3/3: Training model ===" | tee -a "$LOG"
python3 "$TRAIN" --training_config "$CONFIG" --train_model 2>&1 | tee -a "$LOG"

echo "" | tee -a "$LOG"
echo "=== Training complete ===" | tee -a "$LOG"
echo "Model saved to: output/hey_claw/hey_claw.onnx" | tee -a "$LOG"
