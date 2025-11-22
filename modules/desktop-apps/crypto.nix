# Cryptocurrencies desktop apps.

{ config, lib, pkgs, ... }:

let
  electrumApp = import ./crypto-wallet-electrum.nix { inherit pkgs lib; };
in
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
      pkgs.python312Packages.hidapi
      pkgs.python312Packages.libusb1
      pkgs.python313Packages.pyserial
      pkgs.python312Packages.cbor2
      (import ./webapp-coingecko.nix)
      (import ./webapp-mempool.nix)
    ]
    ++ lib.optionals config.curios.desktop.apps.crypto.btc.enable [
      pkgs.bisq2
      electrumApp
      # TODO: bug - Electrum and Sparrow seems to suffer from an outdated python package dependency in 25.05 channel.
      #pkgs.electrum
      #pkgs.sparrow
    ];
    # Add sparrow udev rules for hardware wallets
    #services.udev.packages = lib.mkIf config.curios.desktop.apps.crypto.btc.enable [
    #  pkgs.sparrow
    #];
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
