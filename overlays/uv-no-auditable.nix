final: prev: {
  uv = prev.uv.overrideAttrs (old: {
    nativeBuildInputs = builtins.filter
      (dep: !(builtins.match ".*auditable.*" (builtins.baseNameOf (builtins.toString dep)) != null))
      (old.nativeBuildInputs or []);
  });
}
