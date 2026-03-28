# other program options

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.others = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "REQUIRED other system category programs.";
      };
      openssl.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable openssl cryptographic library.";
      };
      p7zip.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "7zip fork with additional codecs.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.others.enable {
    environment.systemPackages = with pkgs;
      [ htop ] ++ lib.optionals config.curios.others.openssl.enable [ openssl ]
      ++ lib.optionals config.curios.others.p7zip.enable [ p7zip ];
  };
}
