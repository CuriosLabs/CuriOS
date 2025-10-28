# Custom made packages for CuriOS
{ pkgs, lib, ... }:
let
  curios-dotfiles = pkgs.callPackage ../pkgs/curios-dotfiles {};
  curios-manager = pkgs.callPackage ../pkgs/curios-manager {};
  curios-update = pkgs.callPackage ../pkgs/curios-update {};
in {
  environment.systemPackages = [
    curios-dotfiles
    curios-manager
    curios-update
    pkgs.libnotify # required by curios-update
    pkgs.terminaltexteffects # required by curios-manager
    pkgs.gum # required by curios-manager
  ];

  # 'curios-update --check' as a systemd service/timer
  # systemctl --user status curios-updater.timer
  systemd.user = {
    services.curios-updater = {
      enable = true;
      description = "CuriOS system updater check";
      path = with pkgs; [
        coreutils
        curl
        gnutar
        jq
        libnotify
        util-linux
        wget
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/run/current-system/sw/bin/curios-update --check";
      };
      wantedBy = [ ];
    };
    timers.curios-updater = {
      enable = true;
      description = "CuriOS system updater check";
      timerConfig = {
        OnStartupSec = "30s";
        OnUnitInactiveSec = "24h";
        OnUnitActiveSec = "24h";
        RandomizedDelaySec = "2m";
      };
      wantedBy = [ "timers.target" ];
    };
  };
}