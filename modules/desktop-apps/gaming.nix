# Gaming related packages.

{ config, lib, pkgs, ... }:

{
  # Declare options
  options = {
    curios.desktop.gaming = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description =
          "Enable Gaming applications: gamemoderun, Input-Remapper.";
      };
      heroic.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Heroic Games Launcher";
      };
      retroarchFree.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "libRetro RetroArch free version.";
      };
      #retroarchFull.enable = lib.mkOption {
      #  type = lib.types.bool;
      #  default = false;
      #  description = "libRetro RetroArch full version.";
      #};
      steam = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Steam and ProtonGE for Steam.";
        };
        bigpicture.autoStart = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description =
            "Launch Steam in big picture mode on user desktop login.";
          example = false;
        };
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.gaming.enable {
    # Activate ntsync Linux kernel module
    # for proton-ge 10-9+ / Linux kernel 6.14.2+
    boot.kernelModules =
      lib.optionals config.curios.bootefi.kernel.latest [ "ntsync" ];
    # Steam
    # unfree packages required for Steam and Lutris
    nixpkgs.config.allowUnfree = lib.mkForce true;
    programs.steam = {
      enable = lib.mkDefault config.curios.desktop.gaming.steam.enable;
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
      # In Steam, set game property > launch option to "gamemoderun %command%" for Windows only games.
      # See: https://www.protondb.com/ for more launch options.
      # See: https://github.com/FeralInteractive/gamemode
      pkgs.gamemode
      pkgs.steam-run
      (lib.mkIf config.curios.desktop.gaming.steam.bigpicture.autoStart
        (pkgs.makeAutostartItem {
          name = "steam";
          package = pkgs.steam;
          appendExtraArgs = [ "--bigpicture" ];
        }))
    ] ++ lib.optionals config.curios.desktop.gaming.heroic.enable
      [ pkgs.heroic ]
      ++ lib.optionals config.curios.desktop.gaming.retroarchFree.enable
      [ pkgs.retroarch-free ];
  };
}
