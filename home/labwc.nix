{ pkgs, ... }: {
  xdg.configFile."labwc/autostart" = {
    executable = true;
    text = ''
      # Wait for PipeWire socket (HDMI audio)
      socket="/run/user/$(id -u)/pipewire-0"
      for i in $(seq 1 30); do
        [ -e "$socket" ] && break
        sleep 1
      done

      # Chromium kiosk pointing at OpenClaw gateway
      ${pkgs.chromium}/bin/chromium \
        --kiosk \
        --no-first-run \
        --noerrdialogs \
        --disable-session-crashed-bubble \
        --disable-pinch \
        --overscroll-history-navigation=0 \
        --remote-debugging-port=9222 \
        http://localhost:18789 &
    '';
  };

  xdg.configFile."labwc/rc.xml".text = ''
    <?xml version="1.0"?>
    <labwc_config>
      <core>
        <gap>0</gap>
      </core>
      <windowRules>
        <windowRule identifier="chromium" matchOnce="true">
          <action name="Maximize" />
          <action name="ToggleDecoration" />
        </windowRule>
      </windowRules>
    </labwc_config>
  '';

  xdg.configFile."labwc/environment".text = ''
    NIXOS_OZONE_WL=1
  '';
}
