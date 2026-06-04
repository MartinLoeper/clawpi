{ pkgs, lib, config, ... }:
let
  kioskGraphicalConfig = {
    programs.labwc.enable = true;

    # Chrome enterprise policies to disable translation.
    programs.chromium = {
      enable = true;
      extraOpts = {
        TranslateEnabled = false;
      };
    };

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
in
{
  options.services.clawpi.kiosk = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the kiosk graphical stack (labwc + greetd auto-login for kiosk user)
        and expose a runtime kiosk specialisation for deploy compatibility.
        Disable when importing the ClawPi module into an existing system that
        already has its own display manager / compositor.
      '';
    };
  };

  config = lib.mkIf config.services.clawpi.kiosk.enable (lib.mkMerge [
    # Keep greetd in the base system for reliable boot/session startup.
    kioskGraphicalConfig

    # Also expose a kiosk specialisation so deploy --specialisation kiosk works.
    { specialisation.kiosk.configuration = kioskGraphicalConfig; }
  ]);
}
