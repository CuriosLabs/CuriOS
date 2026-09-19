# Engineering desktop applications - CAD, electronics, 3D.

{ config, lib, pkgs, ... }:

let opencadstudioApp = pkgs.callPackage ../../pkgs/opencadstudio { };
in {
  # Declare options
  options = {
    curios.desktop.engineering = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Engineering applications";
      };
      blender.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Blender - Free and open source 3D creation suite.";
      };
      f3d.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "f3d - Fast and minimalist 3D viewer.";
      };
      freecad.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "FreeCAD - Parametric 3D modeler for CAD, MCAD, CAx.";
      };
      kicad.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "KiCad - Electronics design automation (EDA) suite.";
      };
      librecad.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "LibreCAD - Open source 2D CAD application.";
      };
      opencad-studio.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open CAD Studio - 2D/3D CAD for DWG and DXF.";
      };
      orca-slicer.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "OrcaSlicer - Slicer for 3D printers.";
      };
    };
  };

  # Declare configuration
  config = lib.mkIf config.curios.desktop.engineering.enable {
    environment.systemPackages =
      lib.optionals config.curios.desktop.engineering.blender.enable
      [ pkgs.blender ]
      ++ lib.optionals config.curios.desktop.engineering.f3d.enable [ pkgs.f3d ]
      ++ lib.optionals config.curios.desktop.engineering.freecad.enable
      [ pkgs.freecad ]
      ++ lib.optionals config.curios.desktop.engineering.kicad.enable
      [ pkgs.kicad ]
      ++ lib.optionals config.curios.desktop.engineering.librecad.enable
      [ pkgs.librecad ] ++ lib.optionals
      (config.curios.desktop.engineering.opencad-studio.enable
        && config.curios.platform.amd64.enable) [ opencadstudioApp ]
      ++ lib.optionals config.curios.desktop.engineering.orca-slicer.enable
      [ pkgs.orca-slicer ];
  };
}
