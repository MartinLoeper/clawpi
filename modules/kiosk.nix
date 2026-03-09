{ pkgs, ... }:
{
  specialisation.kiosk.configuration = {
    programs.labwc.enable = true;

    services.greetd = {
      enable = true;
      settings = {
        initial_session = {
          command = "${pkgs.labwc}/bin/labwc";
          user = "kiosk";
        };
        default_session = {
          command = "${pkgs.labwc}/bin/labwc";
          user = "kiosk";
        };
      };
    };
  };
}
