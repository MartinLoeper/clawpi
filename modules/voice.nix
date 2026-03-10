{ lib, pkgs, config, ... }:
let
  cfg = config.services.clawpi.voice;

  # Map assistant names to their wake word model files
  assistantModels = {
    claw = "${pkgs.hey-claw-model}/share/openwakeword/models/hey_claw.onnx";
    jarvis = "${pkgs.openwakeword}/lib/python3*/site-packages/openwakeword/resources/models/hey_jarvis_v0.1.onnx";
  };
in
{
  options.services.clawpi.voice = {
    enable = lib.mkEnableOption "voice pipeline (hotword detection + speech-to-text)";

    assistantName = lib.mkOption {
      type = lib.types.enum [ "claw" "jarvis" ];
      default = "claw";
      description = ''
        Name of the voice assistant persona. Determines which bundled
        wake word model is used (e.g. "claw" → "hey claw", "jarvis" → "hey jarvis").
        Ignored when wakewordModel is set explicitly.
      '';
    };

    wakewordModel = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a custom wake word model file (.onnx or .tflite).
        When null, the model is determined by assistantName.
      '';
    };

    threshold = lib.mkOption {
      type = lib.types.float;
      default = 0.8;
      description = "Wake word detection threshold (0.0–1.0). Lower = more sensitive.";
    };

    silenceTimeout = lib.mkOption {
      type = lib.types.float;
      default = 1.5;
      description = "Seconds of silence before stopping speech recording.";
    };

    maxRecordSeconds = lib.mkOption {
      type = lib.types.float;
      default = 15.0;
      description = "Maximum speech recording duration in seconds.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.clawpi-voice-pipeline
    ] ++ lib.optional (cfg.wakewordModel == null && cfg.assistantName == "claw") pkgs.hey-claw-model;
  };
}
