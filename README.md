# fedora setup script

a simple script to automate setting up a fresh fedora workstation installation.

## what it does

this script helps you:

*   configure dnf and add rpm fusion repositories.
*   update the system.
*   install nvidia drivers (optional, requires latest kernel).
*   install common applications (like chrome, telegram, steam, obs, etc.) via dnf and flatpak.
*   install creative tools (gimp, krita, etc.).
*   install programming tools (zed editor, rust).
*   install gui configuration helpers (flatseal, dconf-editor).
*   install various other useful apps and utilities.
*   install gnome extensions and apply some basic configuration.
*   populate the Templates folder
*   set up a systemd service for graceful chrome shutdown (optional).
*   add custom udev rules (optional).

## prerequisites

*   a relatively fresh installation of fedora workstation (tested vaguely around version 42).
*   internet connection.
*   running the script with `sudo` is required.
*   it's recommended to update your system and reboot *before* running this script for the best results (especially if installing nvidia drivers).

## required files

this script needs some extra files and directories to be in the same directory as the script itself when you run it:

*   `burn-my-windows/` (directory with gnome extension config)
*   `tiling-assistant/` (directory with gnome extension config)
*   `services/kill-chrome-gracefully.service` (systemd unit file)
*   `udev/netmd.rules` (udev rule file)
*   `udev/92-viia.rules` (udev rule file)
*   `Templates` (directory with all the templates)

the easiest way to achieve this is to do `git clone`

## usage

1.  download the script and the required files/directories mentioned above. place them together.
2.  open a terminal in that directory.
3.  make the script executable:
    `chmod +x your_script_name.sh`
4.  run the script with sudo:
    `sudo ./your_script_name.sh`

### options

*   **interactive (default):** `sudo ./your_script_name.sh`
    the script will ask you yes/no questions for each major section.
*   **full install:** `sudo ./your_script_name.sh -y` or `sudo ./your_script_name.sh --yes`
    runs the full installation without asking any questions (answers 'y' to everything).
*   **help:** `sudo ./your_script_name.sh --help`
    displays a short help message.
