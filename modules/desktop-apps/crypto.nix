# Cryptocurrencies desktop apps.

{ config, lib, pkgs, ... }:

let electrumApp = import ./crypto-wallet-electrum.nix { inherit pkgs lib; };
in {
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
        description =
          "Bitcoin - Electrum, Sparrow wallets - Bisq2 decentralized exchange - Coingecko webapp.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.apps.crypto.enable {
    environment.systemPackages = [
      pkgs.secp256k1
      (import ./webapp-coingecko.nix)
      (import ./webapp-mempool.nix)
    ] ++ lib.optionals config.curios.desktop.apps.crypto.btc.enable [
      pkgs.bisq2
      electrumApp
      pkgs.sparrow
    ];
    # Add sparrow udev rules for hardware wallets
    services.udev.packages =
      lib.mkIf config.curios.desktop.apps.crypto.btc.enable [ pkgs.sparrow ];
    # Custom udev rules for hardware wallets
    services.udev.extraRules = ''
      # Blockstream Jade
      SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d4", MODE="0666", GROUP="plugdev"
      # Other hardware wallets (ex: Ledger, Trezor)
      SUBSYSTEM=="usb", ATTRS{idVendor}=="2c97", MODE="0666", GROUP="plugdev"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="1209", MODE="0666", GROUP="plugdev"
    '';
  };
}
