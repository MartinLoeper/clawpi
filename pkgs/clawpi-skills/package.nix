{ lib, stdenvNoCC, python3, yt-dlp, makeWrapper }:

stdenvNoCC.mkDerivation {
  pname = "clawpi-skills";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Install the video-watcher skill
    mkdir -p $out/share/clawpi-skills/video-watcher/scripts
    cp video-watcher/SKILL.md $out/share/clawpi-skills/video-watcher/
    cp video-watcher/scripts/get_transcript.py $out/share/clawpi-skills/video-watcher/scripts/

    # Wrap the Python script so yt-dlp and python3 are on PATH
    makeWrapper ${python3}/bin/python3 $out/bin/video-watcher-transcript \
      --prefix PATH : ${lib.makeBinPath [ yt-dlp ]} \
      --add-flags "$out/share/clawpi-skills/video-watcher/scripts/get_transcript.py"

    runHook postInstall
  '';

  meta = {
    description = "OpenClaw skill bundle for ClawPi — video transcript fetching and more";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
