# Gaming related packages.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.apps.gaming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "Enable desktop apps for gaming: Steam, gamemoderun, Teamspeak6, input-remapper.";
      };
      steam.bigpicture.autoStart = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Launch Steam in big picture mode on user desktop login.";
        example = false;
      };
    };
  };
  # TODO: add RetroArch

  # Declare configuration
  config = lib.mkIf config.curios.desktop.apps.gaming.enable {
    # Steam
    # unfree packages required for Steam and Lutris
    nixpkgs.config.allowUnfree = lib.mkForce true;
    programs.steam = {
      enable = true;
      #remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      #dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      #localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
      extraCompatPackages = with pkgs;
        [
          proton-ge-bin # proton-ge-custom by GloriousEggroll
        ];
    };

    # Various packages
    services.input-remapper = { enable = true; };
    environment.systemPackages = [
      # Heroic launcher
      pkgs.heroic
      # In Steam, set game property > launch option to "gamemoderun %command%" for Windows only games.
      # See: https://www.protondb.com/ for more launch options.
      # See: https://github.com/FeralInteractive/gamemode
      pkgs.gamemode
      pkgs.steam-run
      (lib.mkIf config.curios.desktop.apps.gaming.steam.bigpicture.autoStart
        (pkgs.makeAutostartItem {
          name = "steam";
          package = pkgs.steam;
          appendExtraArgs = [ "--bigpicture" ];
        }))
    ];
  };
}
