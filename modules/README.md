# Curi*OS* modules

Activate or deactivate modules by using the `curios-manager` TUI `Applications`
menu then `Install/Uninstall CuriOS Apps`.
**OR** by modifying `modules.json` file: `sudo nano /etc/nixos/modules.json` and
then rebuild nixos: `sudo nixos-rebuild switch`. The `modules.json` file can be
regenerated with the command `sudo curios-update --export`.
