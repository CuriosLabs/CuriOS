# CuriOS core configuration, packages and options
{ lib, pkgs, ... }:
let
  curios-manager = pkgs.callPackage ../pkgs/curios-manager { };
  snitch = pkgs.callPackage ../pkgs/snitch { };
in {
  # Declare options
  options = {
    curios.core.source = {
      branch = lib.mkOption {
        type = lib.types.str;
        default = "master";
        description = "CuriOS Git respository branch to use.";
      };
      url = lib.mkOption {
        type = lib.types.str;
        default = "https://github.com/CuriosLabs/CuriOS.git";
        description = "CuriOS Git respository URL.";
      };
      revision = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "";
        description =
          "The Git revision from which this CuriOS configuration was built.";
      };
    };
  };

  # Declare configuration
  config = { environment.systemPackages = [ curios-manager snitch ]; };
}

