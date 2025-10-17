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
    environment.systemPackages = with pkgs; [
      # Will use brave browser for webapps later
      brave
      sparrow
    ]
    ++ lib.optionals config.curios.desktop.apps.crypto.btc.enable [
      bisq2
      electrum
    ];
    # Add sparrow udev rules for hardware wallets
    services.udev.packages = [
      pkgs.sparrow
    ];
  };
}