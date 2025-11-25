# Various developer desktop apps.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.apps.devops = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Desktop apps for developers - Neovim, git for github (gh), shellcheck, statix.";
      };
      cloudflared.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Cloudflare tunnel client.";
      };
      editor = {
        default.nvim.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Set Neovim as the default editor instead of nano.";
        };
        zed.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Zed - High-performance editor written in Rust.";
        };
        vscode.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Code editor by Microsoft.";
        };
      };
      go.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Go, gofmt and JetBrains GoLand.";
      };
      javascript.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "NodeJS (npm).";
      };
      python312.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Python3.12, pip3, UV and JetBrains PyCharm Community.";
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
      defaultEditor = config.curios.desktop.apps.devops.editor.default.nvim.enable;
      viAlias = true;
      vimAlias = true;
    };
    # TODO: neovim plugins like lazyvim
    # other dev apps
    environment.systemPackages = with pkgs; [
      # Devops
      git-who
      gh
      whois
      # Bash linter
      shellcheck
      # Nix linter
      statix
      #lefthook
      # Neovim plugins / dependencies:
      vimPlugins.LazyVim
      vimPlugins.nvim-treesitter
      clang
      #libclang ??
    ]
    ++ lib.optionals config.curios.desktop.apps.devops.cloudflared.enable [
      cloudflared
    ]
    ++ lib.optionals config.curios.desktop.apps.devops.go.enable [
      go
      golangci-lint
      jetbrains.goland
    ]
    ++ lib.optionals config.curios.desktop.apps.devops.javascript.enable [
      nodejs_22
    ]
    ++ lib.optionals config.curios.desktop.apps.devops.python312.enable [
      # Python3
      python312Full
      python312Packages.pip
      python312Packages.setuptools
      python312Packages.cryptography
      python312Packages.uv
      jetbrains.pycharm-community-bin
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
      # VNC
      remmina
    ]
    ++ lib.optionals config.curios.desktop.apps.devops.editor.zed.enable [
      nil
      nixd
      zed-editor
    ]
    ++ lib.optionals config.curios.desktop.apps.devops.editor.vscode.enable [
      vscode-fhs
    ];
  };
}
