final: prev:
let
  fixDeps = drv: drv.overrideAttrs (old: {
    postPhases = (old.postPhases or []) ++ [ "fixMissingDeps" ];
    fixMissingDeps = ''
      # Work around missing 'long' dependency for @whiskeysockets/baileys in pnpm layout.
      long_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/long@5.*/node_modules/long" -print | head -n 1)"
      baileys_pkgs="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/@whiskeysockets+baileys*/node_modules/@whiskeysockets/baileys" -print)"
      if [ -n "$long_src" ] && [ -n "$baileys_pkgs" ]; then
        for pkg in $baileys_pkgs; do
          if [ ! -e "$pkg/node_modules/long" ]; then
            mkdir -p "$pkg/node_modules"
            ln -s "$long_src" "$pkg/node_modules/long"
          fi
        done
      fi

      # Work around missing '@vector-im/matrix-bot-sdk' for the Matrix extension.
      # The package is in the pnpm store but the extension's createRequire() can't resolve it.
      matrix_bot_sdk_src="$(find "$out/lib/openclaw/node_modules/.pnpm" \
        -path "*/@vector-im+matrix-bot-sdk*/node_modules/@vector-im/matrix-bot-sdk" \
        -print | head -n 1)"
      matrix_extension="$out/lib/openclaw/extensions/matrix"
      if [ -n "$matrix_bot_sdk_src" ] && [ -d "$matrix_extension" ]; then
        mkdir -p "$matrix_extension/node_modules/@vector-im"
        if [ ! -e "$matrix_extension/node_modules/@vector-im/matrix-bot-sdk" ]; then
          ln -s "$matrix_bot_sdk_src" "$matrix_extension/node_modules/@vector-im/matrix-bot-sdk"
        fi
      fi
    '';
  });
in {
  openclaw-gateway = fixDeps prev.openclaw-gateway;
}
