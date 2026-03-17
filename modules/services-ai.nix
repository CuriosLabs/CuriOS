# Must be imported by configuration.nix
# AI tools packages.
# DEPRECATED - moved to services.nix:

{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.services.ai.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Ollama(local AI) and open-webui services.";
    };
  };

  config = lib.mkIf config.curios.services.ai.enable {
    # Ollama, see: https://wiki.nixos.org/wiki/Ollama
    # For a ZSH integration, see: https://github.com/CuriosLabs/curios-dotfiles
    services.ollama = {
      enable = true;
      #home = "/home/ollama";
      # Optional: preload models, see https://ollama.com/library
      # or use `ollama pull <model-name>` (may be faster)
      #loadModels = [ "mistral-nemo:latest" ]; # get download status with: 'systemctl status ollama-model-loader.service'
      # GPU accel
      # "false": 100% CPU, "cuda": modern Nvidia GPU, "rocm": modern AMD GPU
      acceleration = if config.curios.hardware.nvidiaGpu.enable then
        "cuda"
      else if config.curios.hardware.amdGpu.enable then
        "rocm"
      else if config.curios.hardware.intelGpu.enable then
        "vulkan"
      else
        false;
      # Ollama server port
      port = 11434;
    };
    # Open WebUI, see: https://docs.openwebui.com/
    services.open-webui = {
      enable = true;
      environment = {
        # See https://docs.openwebui.com/getting-started/env-configuration/
        HOME = "/var/lib/open-webui";
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
        # Disable authentication
        WEBUI_AUTH = "False";
      };
      port = 8080;
    };
    # AI webapp desktop shortcuts
    environment.systemPackages = [ (import ./desktop-apps/webapp-ollama.nix) ];
  };
}
