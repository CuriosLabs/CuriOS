{ lib, oo7, oo7-server, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "oo7-pam";
  inherit (oo7) version src cargoHash;

  buildAndTestSubdir = "pam";

  # The upstream PAM module hardcodes /usr/libexec/oo7-daemon as the daemon
  # path when auto_start is used.  Patch it to the Nix store path so the
  # daemon can actually be launched on NixOS.
  postPatch = ''
    substituteInPlace pam/src/socket.rs \
      --replace-fail '/usr/bin/oo7-daemon' '${oo7-server}/libexec/oo7-daemon'
  '';

  postInstall = ''
    mkdir -p $out/lib/security
    # cargoInstallHook places the .so in $out/lib as libpam_oo7.so
    if [ -e "$out/lib/libpam_oo7.so" ]; then
      cp "$out/lib/libpam_oo7.so" "$out/lib/security/pam_oo7.so"
    elif [ -e "pam/target/release/libpam_oo7.so" ]; then
      cp "pam/target/release/libpam_oo7.so" "$out/lib/security/pam_oo7.so"
    else
      echo "Could not find libpam_oo7.so"
      exit 1
    fi
  '';

  meta = {
    inherit (oo7.meta)
      homepage
      changelog
      license
      maintainers
      platforms
      ;
    description = "${oo7.meta.description} (PAM module)";
  };
}
