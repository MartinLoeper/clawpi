final: prev: {
  clawpi = final.callPackage ../pkgs/clawpi/package.nix { };
  clawpi-tools = final.callPackage ../pkgs/clawpi-tools/package.nix { };
  whisper-model = final.callPackage ../pkgs/whisper-model.nix { };
}
