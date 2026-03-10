{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "hey-claw-model";
  version = "0.1.0";

  src = ./hey_claw.onnx;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/openwakeword/models
    cp $src $out/share/openwakeword/models/hey_claw.onnx
  '';

  meta = {
    description = "Custom 'hey claw' wake word model for openWakeWord";
    license = lib.licenses.asl20;
  };
}
