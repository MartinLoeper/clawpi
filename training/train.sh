#!/usr/bin/env bash
# Train the "hey claw" wake word model end-to-end.
# Run inside the training devShell after setup.sh has completed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

CONFIG="hey_claw.yml"
TRAIN="openwakeword/openwakeword/train.py"

if [ ! -f "$TRAIN" ]; then
  echo "Error: openWakeWord not found. Run ./setup.sh first."
  exit 1
fi

# Ensure local clones and pip packages are on PYTHONPATH
PIP_SITE="$SCRIPT_DIR/.pip/lib/python3.*/site-packages"
# shellcheck disable=SC2086
export PYTHONPATH="$SCRIPT_DIR/openwakeword:$SCRIPT_DIR/piper-sample-generator:$(echo $PIP_SITE):${PYTHONPATH:-}"

# Create output directory
mkdir -p output/hey_claw

echo "=== Step 1/3: Generating synthetic clips ==="
python3 "$TRAIN" --training_config "$CONFIG" --generate_clips

echo ""
echo "=== Step 2/3: Augmenting clips ==="
python3 "$TRAIN" --training_config "$CONFIG" --augment_clips

echo ""
echo "=== Step 3/3: Training model ==="
# train_model exports .onnx successfully but then tries (and fails) to also
# convert to TFLite via onnx_tf, which we don't need. Tolerate that error.
python3 "$TRAIN" --training_config "$CONFIG" --train_model || true

# Verify the ONNX model was actually created
if [ ! -f "output/hey_claw/hey_claw.onnx" ]; then
  echo "ERROR: Training failed — no .onnx model found."
  exit 1
fi

echo ""
echo "=== Training complete ==="
echo "Model saved to: output/hey_claw/hey_claw.onnx"
echo ""
echo "To test with your microphone:"
echo "  python openwakeword/examples/detect_from_microphone.py --model_path output/hey_claw/hey_claw.onnx"
echo ""
echo "To deploy to the Pi, copy the .onnx file and set:"
echo "  services.clawpi.voice.wakewordModel = ./training/output/hey_claw/hey_claw.onnx;"
