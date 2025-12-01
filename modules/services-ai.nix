# Must be imported by configuration.nix
# AI tools packages.

{ config, lib, ... }:

{
  # Declare options
  options = {
    curios.services.ai.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "Enable Ollama and open-webui services - ChatGPT, Grok, Mistral, Ollama(local) webapps.";
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
      else
        "false";
    };
    # Open WebUI, see: https://docs.openwebui.com/
    services.open-webui = {
      enable = true;
      environment = {
        HOME = "/var/lib/open-webui";
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
        # Disable authentication
        WEBUI_AUTH = "False";
      };
    };
    # AI webapp desktop shortcuts
    environment.systemPackages = [ (import ./desktop-apps/webapp-ollama.nix) ];
  };
}
