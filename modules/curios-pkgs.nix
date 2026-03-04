# Custom made packages for CuriOS
{ pkgs, ... }:
let
  curios-dotfiles = pkgs.callPackage ../pkgs/curios-dotfiles { };
  curios-manager = pkgs.callPackage ../pkgs/curios-manager { };
  curios-manager-applet = pkgs.callPackage ../pkgs/curios-manager-applet { };
  snitch = pkgs.callPackage ../pkgs/snitch { };
in {
  environment.systemPackages =
    [ curios-dotfiles curios-manager curios-manager-applet snitch ];

  # 'curios-update --check' as a systemd service/timer
  # systemctl --user status curios-updater.timer
  systemd.user = {
    services.curios-updater = {
      enable = true;
      description = "CuriOS system updater check";
      path = with pkgs; [ coreutils curl gnutar jq libnotify util-linux wget ];
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
