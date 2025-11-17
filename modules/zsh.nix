# ZSH shell.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.shell.zsh.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "CuriOS ZSH config.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.shell.zsh.enable {
    environment.systemPackages = with pkgs; [
      # For ZSH:
      bat # cat replacement
      duf # df replacement
      dust # du replacement
      eza # ls replacement
      fd # find alternative
      fzf # fuzzy finder
      jq # JSON parser
      terminaltexteffects
      zoxide # Better cd
    ];
    # ZSH
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
    };
    users.defaultUserShell = pkgs.zsh;
    # minimalistic default zshrc
    #environment.etc."skel/.zshrc".text = ''
    #  autoload -Uz promptinit && promptinit
    #'';
    # /etc/skel/.zshrc is now updated by curios-install during ISO install
  };
}
