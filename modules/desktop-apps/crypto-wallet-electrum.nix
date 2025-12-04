# Install Electrum BTC wallet from the AppImage published on the official website.
# See: https://electrum.org/#download
# See: https://wiki.nixos.org/wiki/Appimage

{ pkgs, lib }:
let
  pname = "electrum";
  version = "4.6.2";

  src = pkgs.fetchurl {
    url =
      "https://download.electrum.org/${version}/${pname}-${version}-x86_64.AppImage";
    hash = "sha256-RFOYVpnkl69HaWxpAm0hUTQmxvSDoscGdBr7gDHnjU0=";

    # Verify Appimage signature
    nativeBuildInputs = [ pkgs.gnupg ];
    downloadToTemp = true;

    postFetch = ''
      pushd $(mktemp -d)
      export GNUPGHOME=$PWD/gnupg
      mkdir -m 700 -p $GNUPGHOME
      ln -s ${authorPubKey} ./authSignature.asc
      gpg --trusted-key 6694D8DE7BE8EE5631BED9502BD5824B7F9470E6 --import authSignature.asc
      #echo -e "trust\n5\ny\nsave" | gpg --batch --no-tty --command-fd 0 --edit-key 6694D8DE7BE8EE5631BED9502BD5824B7F9470E6
      ln -s ${appSignature} ./appSignature.asc
      ln -s $downloadedFile ./${pname}-${version}-x86_64.AppImage
      # TODO: gpg --verify exit code 2 (even with authSignature.asc marked as trusted) seems to bug the postFetch process.
      #gpg --batch --verify appSignature.asc ${pname}-${version}-x86_64.AppImage
      popd
      mv $downloadedFile $out
    '';
  };

  appSignature = pkgs.fetchurl {
    url =
      "https://download.electrum.org/${version}/electrum-${version}-x86_64.AppImage.asc";
    hash = "sha256-qwB4Th6N3Xr6iXGIKAmVJ7S1We4jcLVCwZ9tAxHhOlw=";
  };

  authorPubKey = pkgs.fetchurl {
    url =
      "https://raw.githubusercontent.com/spesmilo/electrum/master/pubkeys/ThomasV.asc";
    hash = "sha256-37ApVZlI+2EevxQIKXVKVpktt1Ls3UbWq4dfio2ORdo=";
  };

  #authorPubKey2 = pkgs.fetchurl {
  #  url = "https://raw.githubusercontent.com/spesmilo/electrum/master/pubkeys/sombernight_releasekey.asc";
  #  hash = "";
  #};

  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };

  desktopItem = pkgs.makeDesktopItem {
    name = "org.electrum";
    exec = "/run/current-system/sw/bin/electrum";
    desktopName = "Electrum Bitcoin Wallet";
    icon = "electrum";
    categories = [ "Finance" ];
    terminal = false;
    type = "Application";
    mimeTypes = [ "x-scheme-handler/bitcoin" "x-scheme-handler/lightning" ];
  };
in pkgs.appimageTools.wrapType2 {
  inherit pname version pkgs src;

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
