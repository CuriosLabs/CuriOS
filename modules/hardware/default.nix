# Imports every other configurations files from here.

{ ... }: {
  imports = [ ./amd-gpu.nix ./intel-gpu.nix ./laptop.nix ./nvidia-gpu.nix ./various.nix ];
}
