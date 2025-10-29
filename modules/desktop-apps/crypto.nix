# Cryptocurrencies desktop apps.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.apps.crypto = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Desktop apps for crypto bros.";
      };
      btc.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Bitcoin - Electrum, Sparrow wallets - Bisq2 decentralized exchange - Coingecko webapp.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.apps.crypto.enable {
    environment.systemPackages = [
      pkgs.secp256k1
      pkgs.python312Packages.cryptography
      pkgs.python313Packages.pyserial
      pkgs.python312Packages.cbor2
      (import ./webapp-coingecko.nix)
    ]
    ++ lib.optionals config.curios.desktop.apps.crypto.btc.enable [
      pkgs.bisq2
      # TODO: bug - Electrum and Sparrow seems to suffer from an outdated python package dependency in 25.05 channel.
      #pkgs.electrum
      #pkgs.sparrow
    ];
    # Add sparrow udev rules for hardware wallets
    #services.udev.packages = lib.mkIf config.curios.desktop.apps.crypto.btc.enable [
    #  pkgs.sparrow
    #];
  };
}