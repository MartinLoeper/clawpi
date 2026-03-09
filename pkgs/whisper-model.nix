{ lib, fetchurl, model ? "base" }:

let
  models = {
    tiny = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin";
      hash = "sha256-VLSQ/jJhkWRQU0t3sMfKsMR1pN6JjGnnFNJMOrsRwUo=";
    };
    base = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin";
      hash = "sha256-I7BYPG+IhJi7TFyClEcHCTqhGj0GA97E8LJnMJiLQ10=";
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
