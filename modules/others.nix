# other program options

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.others = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Other system's category programs.";
      };
      openssl.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable openssl cryptographic library.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.others.enable {
    environment.systemPackages = with pkgs;
      [ htop ] ++ lib.optionals config.curios.others.openssl.enable [ openssl ];
  };
}
