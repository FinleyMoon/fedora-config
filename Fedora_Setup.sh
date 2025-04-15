#!/bin/bash
set -euo pipefail

# Determine the script's directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [[ "$(id -u)" -eq 0 ]]; then
  echo Script is running as root
else
  echo "script must be running as root. please run with sudo."
  exit 1 # Exit with an error code to indicate sudo is required
fi
echo loading...

original_user="$SUDO_USER"
if [[ -z "$original_user" ]]; then
  echo "error: Could not reliably determine the original user.  "
  echo "SUDO_USER is not set"
  exit 1
fi

set_full_install () {
	update=y
	nvidia=y
	install_basic_apps=y
	install_hiddify=y
	install_create=y
	install_guiconf=y
	install_programming=y
	install_other_apps=y
	install_extensions=y
	templates=y
	make_chrome_shutdown=y
	add_udev=y
	clear
	echo "|-------------------------------------|"
	echo "|-----starting a full installation----|"
	echo "|-------------------------------------|"
	sleep 2
}

check () {
  local oinput="$1"
  local input="${oinput,,}"
  while [[ "$input" != "y" && "$input" != "n" ]]; do
    echo "invalid input. enter y or n." >&2 # Redirect error to stderr
    read input
  done
  echo "${input,,}" # Validated input to stdout
}

ask_questions () {
	# Removed dnf config question as requested
	echo update system? [y/n] # Assuming this was intended - added prompt text
	read update
	update=$(check $update)

	echo install nvidia drivers? [y/n]
	read nvidia
	nvidia=$(check $nvidia)

	echo install basic apps: chrome, extension manager, tweaks, obs, telegram, appimagelauncher, resources, clapper, mpv, etc? [y/n]
	read install_basic_apps
	install_basic_apps=$(check $install_basic_apps)

	echo install hiddify? [y/n]
	read install_hiddify
	install_hiddify=$(check $install_hiddify)

	echo install creative apps and editors: gimp, rawtherapee, krita, inkscape, handbrake? [y/n]
	read install_create
	install_create=$(check $install_create)

	echo install programming tools: zed editor, rust, etc? [y/n]
	read install_programming
	install_programming=$(check $install_programming)

	echo install gui configuration apps: dconfeditor, flatseal, selinux troubleshooter, helvum? [y/n]
	read install_guiconf
	install_guiconf=$(check $install_guiconf)

	echo install more apps: cartriges, prism launcher, ocrfeeder, shortwave, impression, vaults, bottles, upscaler, drawing, switcheroo, prusaslicer, pdf arranger, signal, amberol, etc? [y/n]
	read install_other_apps
	install_other_apps=$(check $install_other_apps)

	echo install extensions? [y/n]
	read install_extensions
	install_extensions=$(check $install_extensions)
	
	echo populate the Templates folder? [y/n]
	read templates
	templates=$(check $templates)

	echo set up the graceful chrome shutdown service? [y/n]
	read make_chrome_shutdown
	make_chrome_shutdown=$(check $make_chrome_shutdown)

	echo add udev rules for netmd and via keyboards? [y/n]
	read add_udev
	add_udev=$(check $add_udev)

	clear
	echo "|--------------------------------------|"
	echo "|------starting your installation------|"
	echo "|--------------------------------------|"
	sleep 2
}

what_to_do () {
	echo do a full install? [y/n]
	read full
    # Convert to lowercase for reliable comparison
    full_lower=$(echo "$full" | tr '[:upper:]' '[:lower:]')
	if [[ $full_lower = y ]]; then
		set_full_install
	else
		ask_questions
	fi
}

dnf_setup () {
	echo "Setting up DNF..."
    local dnf_conf="/etc/dnf/dnf.conf"
    local marker="## fin.moon DNF additions ##" # Unique marker

    # Check if our marker exists before adding config
    if ! grep -Fxq "$marker" "$dnf_conf"; then
        echo "" >> "$dnf_conf"
        echo "$marker" >> "$dnf_conf"
        echo "# Added by setup script" >> "$dnf_conf"
        echo "defaultyes=True" >> "$dnf_conf"
        echo "max_parallel_downloads=10" >> "$dnf_conf"
        echo "## End fin.moon DNF additions ##" >> "$dnf_conf"
        echo "Added DNF config options (defaultyes=True, max_parallel_downloads=10)."
    else
        echo "DNF config options seem to be already added."
    fi

	# Always ensure RPM Fusion and OpenH264 are set up
	echo "Ensuring RPM Fusion repositories are installed..."
	dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
	echo "Ensuring OpenH264 repository is enabled..."
	dnf config-manager setopt fedora-cisco-openh264.enabled=1 #works like this
}


extensions () {
	# python3-pip should be installed before calling this function
	echo "Installing and enabling GNOME Extensions..."
	runuser -l "$original_user" -c "pip install --user --upgrade gnome-extensions-cli" # Added --user flag
	runuser -l "$original_user" -c "gnome-extensions-cli install primary_input_on_lockscreen@sagidayan.com caffeine@patapon.info tiling-assistant@leleat-on-github burn-my-windows@schneegans.github.com pip-on-top@rafostar.github.com clipboard-indicator@tudmotu.com mediacontrols@cliffniff.github.com gsconnect@andyholmes.github.io"
	runuser -l "$original_user" -c "gnome-extensions-cli enable appindicatorsupport@rgcjonas.gmail.com"
	runuser -l "$original_user" -c "gnome-extensions-cli disable background-logo@fedorahosted.org"
	#now let's copy configs for some of these using SCRIPT_DIR
    echo "Copying GNOME Extension configurations..."
	cp -r "$SCRIPT_DIR/burn-my-windows" "/home/$original_user/.config/"
	cp -r "$SCRIPT_DIR/tiling-assistant" "/home/$original_user/.config/"
    # Ensure correct ownership after copying as root
    chown -R "$original_user":"$original_user" "/home/$original_user/.config/burn-my-windows"
    chown -R "$original_user":"$original_user" "/home/$original_user/.config/tiling-assistant"
}


main () {
	local nvidia_not_installed=0 # Initialize nvidia flag

	echo "Setting up Flatpak..."
	flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
	flatpak remote-delete fedora
	dnf_setup # Always run dnf_setup


	if [[ $update = "y" ]]; then
		echo "Installing system updates..."
		dnf up -y
	fi


	if [[ $nvidia = "y" ]]; then
        latest_kernel_pkg=$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' | tail -n 1)
        current_kernel=$(uname -r)
        if [[ "$current_kernel" == "$latest_kernel_pkg" ]]; then
            echo "Installing Nvidia drivers (latest kernel detected)..."
            dnf install akmod-nvidia -y
            dnf install xorg-x11-drv-nvidia-cuda -y # Needs nvidia driver first, usually installed as dependency
        else
            nvidia_not_installed=1
            echo "--------------------------------------------------------------------------"
            echo "WARNING: Nvidia drivers NOT installed."
            echo "         You are running kernel '$current_kernel',"
            echo "         but the latest installed kernel package is '$latest_kernel_pkg'."
            echo "         Please reboot into the latest kernel before installing Nvidia drivers."
            echo "         You can install them manually later using:"
            echo "         sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda"
            echo "--------------------------------------------------------------------------"
            sleep 5 # Give user time to read
        fi
	fi


	if [[ $install_basic_apps = "y" ]]; then
        echo "Installing basic applications..."
		dnf install google-chrome-stable gnome-tweaks telegram-desktop mpv steam -y
		dnf install https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm -y || echo "Warning: Failed to install AppImageLauncher. URL might be outdated or package conflict."
		flatpak install flathub com.mattjakeman.ExtensionManager com.obsproject.Studio net.nokyan.Resources com.github.rafostar.Clapper org.gnome.SoundRecorder net.lutris.Lutris -y
	fi


	if [[ $install_hiddify = "y" ]]; then
        echo "Installing Hiddify..."
		dnf install https://github.com/hiddify/hiddify-next/releases/latest/download/Hiddify-rpm-x64.rpm -y || echo "Warning: Failed to install Hiddify. URL might be outdated or package conflict."
	fi


	if [[ $install_guiconf = "y" ]]; then
        echo "Installing GUI configuration tools..."
		dnf install dconf-editor setroubleshoot -y
		flatpak install flathub com.github.tchx84.Flatseal org.pipewire.Helvum -y
	fi

	if [[ $install_programming = "y" ]]; then
        echo "Installing programming tools (Zed, Rust)..."
		# Install Zed for the user
        echo "Installing Zed Editor for user $original_user..."
		runuser -l "$original_user" -c "curl -f https://zed.dev/install.sh | sh"
		# Install Rust for the user
        echo "Installing Rust via rustup for user $original_user..."
		runuser -l "$original_user" -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path'
        echo "Note: User $original_user may need to log out and back in or run 'source \$HOME/.cargo/env' for Rust/Cargo commands to be available in the current session."
	fi

	if [[ $install_create = "y" ]]; then
        echo "Installing creative applications..."
		dnf install rawtherapee inkscape -y
		flatpak install flathub org.gimp.GIMP org.kde.krita fr.handbrake.ghb -y
	fi


	if [[ $install_extensions = "y" ]]; then
		echo "Preparing for GNOME Extension installation..."
		# Install pip system-wide if needed for extensions
		dnf install python3-pip -y
		clear
		extensions # Call the extensions function
	fi
	
	if [[ $templates = "y" ]]; then
        # Define source and destination paths
        local source_templates_dir="$SCRIPT_DIR/Templates"
        local dest_templates_dir="/home/$original_user/Templates"

        # Check if the source Templates directory exists
        if [[ -d "$source_templates_dir" ]]; then
            echo "Populating the Templates folder..."

            # Ensure the user's Templates directory exists (run as user for correct permissions initially)
            runuser -l "$original_user" -c "mkdir -p '$dest_templates_dir'"

            # Copy the *contents* of the source directory into the destination directory
            # Using cp -rT avoids creating Templates inside Templates if $dest_templates_dir already existed
            # Alternatively, 'cp -r "$source_templates_dir/." "$dest_templates_dir/"' often works well too.
            echo "Copying files from $source_templates_dir to $dest_templates_dir"
            cp -rT "$source_templates_dir" "$dest_templates_dir"

            # Ensure correct ownership of all files/subdirs within the user's Templates dir
            echo "Setting ownership for $dest_templates_dir"
            chown -R "$original_user":"$original_user" "$dest_templates_dir"

            echo "Templates folder populated."
        else
            echo "Warning: Source directory '$source_templates_dir' not found. Skipping template population."
        fi
	fi

	if [[ $make_chrome_shutdown = "y" ]]; then
        echo "Setting up graceful Chrome shutdown service..."
		cp "$SCRIPT_DIR/services/kill-chrome-gracefully.service" /etc/systemd/system/
		systemctl daemon-reload # Reload systemd to recognize the new service
		systemctl enable kill-chrome-gracefully.service # Enable it
        echo "Graceful Chrome shutdown service enabled and started."
	fi

	if [[ $add_udev = "y" ]]; then
        echo "Adding udev rules..."
		cp "$SCRIPT_DIR/udev/netmd.rules" /etc/udev/rules.d/
		cp "$SCRIPT_DIR/udev/92-viia.rules" /etc/udev/rules.d/
		udevadm control --reload-rules && udevadm trigger # Reload rules and trigger events
        echo "Udev rules reloaded."
	fi

}

clear
echo
echo "                       |------------------------------------------|"
echo "                       |-------------------hello!-----------------|"
echo "                       |---welcome to my Fedora install script!---|"
echo "                       |----------the script version is:----------|"
echo "                       |---------------------42-------------------|"
echo "                       |------------------------------------------|"
echo
echo
echo
echo "updating your system prior to running this script and rebooting will lead to a better result"
echo "warning: while this script includes some checks, it is recommended that you only run it on a fresh install"
echo "warning 2: the script does some things without asking (e.g. removes the fedora flatpak repo. check github for more: https://github.com/FinleyMoon/fedora-config"
sleep 4

# Handle command-line arguments
if [[ "${1:-}" = "-y" || "${1:-}" = "--yes" ]]; then # Accept --yes as well
	set_full_install
elif [[ "${1:-}" = "--help" ]]; then
	echo "Usage: sudo $0 [-y | --yes | --help]"
	echo "  -y, --yes : Perform a full installation without asking questions."
	echo "  --help    : Display this help message."
	echo "  (no args) : Run interactively, asking questions about components."
	echo ""
	echo "This script automates the setup of a Fedora system."
	echo "Find more info/report issues at: https://github.com/FinleyMoon/fedora-config" # REMEMBER TO FILL THIS IN
	exit 0
else
	what_to_do
fi

main

# Final messages
echo ""
echo "|--------------------------------------|"
echo "|-----------Setup Complete-------------|"
echo "|--------------------------------------|"
echo ""

if [[ "$nvidia_not_installed" == "1" ]]; then
	echo "REMINDER: Nvidia drivers were NOT installed because you weren't running the latest kernel."
    echo "          Please reboot into the latest kernel and install them manually if desired:"
    echo "          sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda"
fi
if [[ $install_programming = "y" ]]; then
    echo "REMINDER: For Rust/Cargo commands to work, user $original_user may need to log out and back in,"
    echo "          or run the command: source \$HOME/.cargo/env"
fi
echo ""
echo "That's it, bye!"
exit 0

#parts for later use
#runuser -l "$original_user" -c "flatpak install --user flathub $flatpak_app_id -y"
