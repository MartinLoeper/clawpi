{ pkgs, ... }: {
  boot.loader.raspberry-pi.bootloader = "kernel";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [ "noatime" "noauto" "x-systemd.automount" "x-systemd.idle-timeout=1min" ];
    };
  };

  networking.hostName = "openclaw-rpi5";

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  users.users.kiosk = {
    isSystemUser = true;
    group = "kiosk";
    home = "/var/lib/kiosk";
    createHome = true;
    extraGroups = [ "video" "audio" ];
    linger = true;
  };
  users.groups.kiosk = { };

  environment.systemPackages = with pkgs; [ openclaw-gateway vim ];

  hardware.graphics.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  nix.settings.trusted-users = [ "nixos" ];

  security.rtkit.enable = true;

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";
}
