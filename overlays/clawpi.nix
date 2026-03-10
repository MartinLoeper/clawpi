final: prev: {
  clawpi = final.callPackage ../pkgs/clawpi/package.nix { };
  clawpi-tools = final.callPackage ../pkgs/clawpi-tools/package.nix { };
  clawpi-skills = final.callPackage ../pkgs/clawpi-skills/package.nix { };
  whisper-model = final.callPackage ../pkgs/whisper-model.nix { };
  clawpi-voice-pipeline = final.callPackage ../pkgs/voice-pipeline/package.nix { };
  hey-claw-model = final.callPackage ../pkgs/voice-pipeline/hey-claw-model.nix { };
}
