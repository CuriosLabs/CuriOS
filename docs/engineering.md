# Engineering Applications

Curi*OS* ships an engineering suite for CAD, electronics design (EDA), 3D
printing, and 3D creation. Unlike other categories, **no engineering
application is installed by default** — enable only what you need.

## Enable or disable engineering apps

Install engineering applications via the **Curi*OS* Manager**:

1. Open `curios-manager` (Shortcut: `Super+Return`).
2. Go to the `Applications` menu, then `Install/uninstall CuriOS Apps` menu.
3. Search for `(curios.desktop) engineering` or a specific app name.
4. Toggle the application options that you need (Space bar).
5. Press Enter to Save and `curios-manager` will handle the installation.

From a terminal, you can do the same with `curios-update`. For example, to
install FreeCAD:

```bash
sudo curios-update --update-module curios.desktop.engineering.freecad.enable true && \
sudo curios-update --update
```

## CAD - 2D and 3D

- **FreeCAD**: Open-source parametric 3D modeler for CAD, MCAD, and CAx
  (`curios.desktop.engineering.freecad.enable`).
- **Open CAD Studio**: 2D/3D CAD application for DWG and DXF drawings
  (`curios.desktop.engineering.opencad-studio.enable`). Available on amd64
  only.
- **LibreCAD**: Open-source 2D CAD application
  (`curios.desktop.engineering.librecad.enable`).

## Electronics design

- **KiCad**: A cross-platform and open-source electronics design automation
  (EDA) suite for schematic capture, PCB layout, and much more
  (`curios.desktop.engineering.kicad.enable`).

## 3D printing

- **OrcaSlicer**: An open-source, fast, and feature-rich slicer for 3D
  printers (`curios.desktop.engineering.orca-slicer.enable`).

## 3D creation and visualization

- **Blender**: A free and open-source 3D creation suite for modeling, shading,
  animation, and rendering (`curios.desktop.engineering.blender.enable`).
- **f3d**: A fast and minimalist 3D viewer for quickly inspecting models
  (`curios.desktop.engineering.f3d.enable`).

Example to install all of them at once:

```bash
sudo curios-update --update-module curios.desktop.engineering.enable true && \
sudo curios-update --update-module curios.desktop.engineering.blender.enable true && \
sudo curios-update --update-module curios.desktop.engineering.f3d.enable true && \
sudo curios-update --update-module curios.desktop.engineering.freecad.enable true && \
sudo curios-update --update-module curios.desktop.engineering.kicad.enable true && \
sudo curios-update --update-module curios.desktop.engineering.librecad.enable true && \
sudo curios-update --update-module curios.desktop.engineering.orca-slicer.enable true && \
sudo curios-update --update
```

---
**Next**: [Gaming applications](gaming.md).

**Previous**: [Office applications](office.md)

**Back**: [index](index.md).