# Install Electrum BTC wallet from the AppImage published on the official website.
# See: https://electrum.org/#download
# See: https://wiki.nixos.org/wiki/Appimage

{ pkgs, lib }:
let
  pname = "electrum";
  version = "4.6.2";

  src = pkgs.fetchurl {
    url = "https://download.electrum.org/${version}/electrum-${version}-x86_64.AppImage";
    hash = "sha256-RFOYVpnkl69HaWxpAm0hUTQmxvSDoscGdBr7gDHnjU0=";
  };

  appSignature = pkgs.fetchurl {
    url = "https://download.electrum.org/${version}/electrum-${version}-x86_64.AppImage.asc";
    hash = "";
  };

  authorPubKey = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/spesmilo/electrum/master/pubkeys/ThomasV.asc";
    hash = "";
  };

  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };

  desktopItem = pkgs.makeDesktopItem {
    name = "org.electrum";
    exec = "/run/current-system/sw/bin/electrum";
    desktopName = "Electrum Bitcoin Wallet";
    icon = "electrum";
    categories = [ "Finance" "Network" ];
    terminal = false;
    type = "Application";
    mimeTypes = [ "x-scheme-handler/bitcoin" "x-scheme-handler/lightning" ];
  };
in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;
  pkgs = pkgs;

  #extraInstallCommands = ''
  #  mkdir -p $out/share/applications
  #  install -m 444 -D ${appimageContents}/electrum.desktop $out/share/applications/electrum.desktop
  #  mkdir -p $out/share/icons/hicolor/128x128/apps
  #  install -m 444 -D ${appimageContents}/electrum.png $out/share/icons/hicolor/128x128/apps/electrum.png
  #  substituteInPlace $out/share/applications/electrum.desktop \
  #    --replace-fail 'Exec=electrum %u' 'Exec=${pname}'
  #'';

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    install -m 444 -D ${desktopItem}/share/applications/org.electrum.desktop $out/share/applications/electrum.desktop
    mkdir -p $out/share/icons/hicolor/128x128/apps
    install -m 444 -D ${appimageContents}/electrum.png $out/share/icons/hicolor/128x128/apps/electrum.png
  '';

  meta = {
    description = "Electrum Bitcoin Wallet";
    homepage = "https://electrum.org/";
    downloadPage = "https://electrum.org/#download";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}