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
        default = "stable";
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
  config = {
    environment.systemPackages = [ curios-manager snitch ];

    # CuriOS Git repository allowed signing keys
    etc = {
      "/curios/allowed_signers".text = ''
        david@curioslabs.dev namespaces="git" sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMCcTnhyf/ug309CiILdhbalLyvbGa4k67x/K/ZokmARAAAAGXNzaDpjdXJpb3Mtc2lnbmluZy0yMDI2MDk=
      '';
    };
  };
}

