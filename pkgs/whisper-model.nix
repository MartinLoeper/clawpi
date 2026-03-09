{ lib, fetchurl, model ? "base" }:

let
  models = {
    tiny = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin";
      hash = "sha256-vgfgSOHlma1GNByNKhNWRQl6U4IhZ4t6zdGxkZxuGyE=";
    };
    base = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin";
      hash = "sha256-YO1bw90U7qhWST0zQ0m0BXgt3K8AKNS130CINF+6Lv4=";
    };
    small = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin";
      hash = "sha256-F+KhEeYM8mMJxHqNhbgmwNC5FDKMhzRCsp3OT7THqW8=";
    };
  };

  selected = models.${model} or (throw "Unknown whisper model: ${model}. Choose tiny, base, or small.");
in
fetchurl {
  inherit (selected) url hash;
  name = "ggml-${model}.bin";
  meta = {
    description = "Whisper.cpp GGML model (${model})";
    license = lib.licenses.mit;
  };
}
