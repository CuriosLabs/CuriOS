{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.cowsay ];
  environment.sessionVariables.CURIOS_CUSTOM = "cowsay";
}
