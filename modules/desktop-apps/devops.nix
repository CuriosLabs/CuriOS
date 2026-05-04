# Various developer desktop applications.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.devops = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description =
          "REQUIRED desktop applications for developers - Neovim, git for github (gh), shellcheck, statix.";
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
        go.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "JetBrains GoLand";
        };
        java.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "JetBrains IDEA oss - Kotlin";
        };
        python.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "JetBrains PyCharm Community";
        };
        rust.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "JetBrains RustRover";
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
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "DEPRECATED";
      };
      java.enable = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "DEPRECATED";
      };
      javascript.enable = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "DEPRECATED";
      };
      javascript.bun.enable = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "DEPRECATED";
      };
      just.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Handy way to save and run project-specific commands.";
      };
      python312.enable = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "DEPRECATED";
      };
      python313.enable = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "DEPRECATED";
      };
      ruby.enable = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "DEPRECATED";
      };
      rust.enable = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "DEPRECATED";
      };
      networks.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Nmap, Zenmap, wireshark, remina.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.devops.enable {
    # basic Neovim
    programs.neovim = {
      enable = true;
      package = pkgs.neovim-unwrapped;
      defaultEditor = config.curios.desktop.devops.editor.default.nvim.enable;
      viAlias = true;
      vimAlias = true;
    };
    # other dev apps
    environment.systemPackages = with pkgs;
      [
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
        #vimPlugins.nvim-treesitter # REMOVED for neovim 0.12+
        vimPlugins.fzf-lua
        clang
        # tree-sitter CLI for neovim 0.12+
        tree-sitter
        #libclang ??
        fd
        fzf
        lazygit
        ripgrep
        # YQ - yaml/xml/toml parser
        yq
      ] ++ lib.optionals config.curios.desktop.devops.cloudflared.enable
      [ cloudflared ]
      ++ lib.optionals config.curios.desktop.devops.just.enable [ just ]
      ++ lib.optionals config.curios.desktop.devops.networks.enable [
        # Networks
        nmap
        zenmap
        # TODO: add user to wireshark group?
        # WARNING: hash mismatch in unstable
        #wireshark
        # VNC
        remmina
      ] ++ lib.optionals config.curios.desktop.devops.editor.go.enable
      [ jetbrains.goland ]
      ++ lib.optionals config.curios.desktop.devops.editor.java.enable
      [ jetbrains.idea-oss ]
      ++ lib.optionals config.curios.desktop.devops.editor.python.enable
      [ jetbrains.pycharm-oss ]
      ++ lib.optionals config.curios.desktop.devops.editor.rust.enable
      [ jetbrains.rust-rover ]
      ++ lib.optionals config.curios.desktop.devops.editor.zed.enable [
        nil
        nixd
        zed-editor
      ] ++ lib.optionals config.curios.desktop.devops.editor.vscode.enable
      [ vscode-fhs ];
  };
}
