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
        description = "Bitcoin - Electrum, Sparrow wallets - Bisq2 decentralized exchange.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.apps.crypto.enable {
    environment.systemPackages = [
      pkgs.secp256k1
    ]
    ++ lib.optionals config.curios.desktop.apps.crypto.btc.enable [
      pkgs.bisq2
      pkgs.electrum
      pkgs.sparrow
      (import ./webapp-coingecko.nix)
    ];
    # Add sparrow udev rules for hardware wallets
    services.udev.packages = lib.mkIf config.curios.desktop.apps.crypto.btc.enable [
      pkgs.sparrow
    ];
  };
}