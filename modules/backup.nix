# backup options

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.backup.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "REQUIRED Restic backup CLI.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.backup.enable {
    environment.systemPackages = with pkgs; [ restic ];
  };
}
