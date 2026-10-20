# CuriOS AppArmor profiles — one file per application.
# Each module contributes entries to security.apparmor.policies.

{ ... }: {
  imports = [
    ./brave.nix
    ./discord.nix
    ./evince.nix
    ./onlyoffice.nix
    ./opencode.nix
    ./signal.nix
    ./steam.nix
  ];
}
