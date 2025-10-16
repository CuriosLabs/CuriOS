# Various developer desktop apps.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.apps.devops = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Desktop apps for developers.";
      };
      go.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Go, gofmt and JetBrains GoLand.";
      };
      python312.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Python3.12, pip3 and JetBrains PyCharm Community.";
      };
      rust.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Rust with cargo and JetBrains RustRover.";
      };
      networks.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Nmap, Zenmap, wireshark, remina.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.apps.devops.enable {
    # basic Neovim
    programs.neovim =  {
      enable = true;
      package = pkgs.neovim-unwrapped;
      defaultEditor = false;
      viAlias = true;
      vimAlias = true;
    };
    # TODO: neovim plugins like lazyvim
    # other dev apps
    environment.systemPackages = with pkgs; [
      # Devops
      cloudflared
      git-who
      gh
      whois
      # Bash linter
      shellcheck
      # Nix linter
      statix
      #lefthook
      # VNC
      remmina
    ]
    ++ lib.optionals config.curios.desktop.apps.devops.go.enable [
      go
      golangci-lint
      jetbrains.goland
    ]
    ++ lib.optionals config.curios.desktop.apps.devops.python312.enable [
      # Python3
      python312Full
      python312Packages.pip
      python312Packages.setuptools
      python312Packages.cryptography
      #python312Packages.uv
      jetbrains.pycharm-community
      ruff
    ]
    ++ lib.optionals config.curios.desktop.apps.devops.rust.enable [
      # Rust
      rustup # provide cargo, rustc, rust-analyzer and more
      cargo-c
      jetbrains.rust-rover
      # build tools
      clang
      libxkbcommon
      llvmPackages_20.bintools
      pkg-config
    ]
    ++ lib.optionals config.curios.desktop.apps.devops.networks.enable [
      # Networks
      nmap
      zenmap
      wireshark # TODO: add user to wireshark group
    ];
  };
}
