# Fonts

{ config, lib, pkgs, ... }: {
  # Declare options
  options = {
    curios.fonts.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "REQUIRED essentials fonts.";
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.fonts.enable {
    # See command: 'fc-list'
    fonts = {
      fontconfig = {
        enable = true;
        useEmbeddedBitmaps = true;
        # Iosevka includes the Braille Patterns (U+2800-28FF) used by btop
        # graphs and gum spinners. Adding it as a fallback for the terminal
        # font and for the generic monospace alias prevents terminals like
        # Alacritty (which rely on fontconfig fallback for Braille) from using
        # a proportional font such as DejaVu Sans, rendering Braille as
        # misaligned dots.
        aliases = {
          "JetBrains Mono" = {
            binding = "strong";
            accept = [ "Iosevka" ];
          };
          monospace.accept = [ "Iosevka" ];
        };
      };
      fontDir.enable = true;
      packages = with pkgs;
        [
          dejavu_fonts
          font-awesome
          # Monospace font including Braille glyphs, used as terminal fallback
          iosevka
          jetbrains-mono
          nerd-fonts.fira-code
          nerd-fonts.jetbrains-mono
          noto-fonts-color-emoji
        ] ++ lib.optionals config.curios.cosmic.enable [
          fira
          noto-fonts
          open-sans
        ];
    };
  };
}

