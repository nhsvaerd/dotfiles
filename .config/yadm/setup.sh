#!/bin/bash

echo "🚀 Running GNOME Setup Script..."

# -----------------------------------
# DEFINE PATHS TO PACKAGE LIST FILES
# -----------------------------------
APT_INSTALL_LIST="$HOME/.config/yadm/packages-apt-install.txt"
APT_REMOVE_LIST="$HOME/.config/yadm/packages-apt-remove.txt"
FLATPAK_LIST="$HOME/.config/yadm/packages-flatpak.txt"
DCONF_SETTINGS="$HOME/.config/dconf/user-settings.conf"

# -----------------------------------
# PROMPT FOR DEBUG MODE
# -----------------------------------
DEBUG_LOG="$HOME/setup-gnome.log"
DEBUG_MODE=false

read -rp "Enable debug mode? (Y/N): " DEBUG_INPUT
if [[ "$DEBUG_INPUT" =~ ^[Yy]$ ]]; then
    DEBUG_MODE=true
    echo "📝 Debug mode enabled. Logging errors to $DEBUG_LOG"
    echo "========== $(date) ==========" >> "$DEBUG_LOG"
fi

# Function to log errors and printing to console
log_error() {
    echo "❌ $1" | tee -a "$DEBUG_LOG" >&2
}

# Function to execute commands and log stderr if debug mode is enabled
run_cmd() {
    if [[ $DEBUG_MODE == true ]]; then
        "$@"  2>>"$DEBUG_LOG"
    else
        "$@"
    fi
}

# -----------------------------------
# INSTALL CORE GNOME PACKAGES
# -----------------------------------
echo "📦 Installing core GNOME packages..."
sudo apt-get update
if ! run_cmd sudo apt-get install -y gnome-core gnome-tweaks gnome-shell-extensions gnome-shell-extension-manager pipx; then
    log_error "Failed to install GNOME packages."
fi

# -----------------------------------
# INSTALL FLATPAK & ADD FLATHUB REMOTE
# -----------------------------------
echo "📦 Ensuring Flatpak is installed..."
if ! run_cmd sudo apt-get install -y flatpak; then
    log_error "Failed to install Flatpak."
fi

# Ensure Flathub is configured
if ! flatpak remote-list | grep -q "flathub"; then
    echo "📦 Adding Flathub remote..."
    if ! run_cmd flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        log_error "Failed to add Flathub remote."
    fi
else
    echo "✅ Flathub remote is already configured."
fi


# -----------------------------------
# APPLY GNOME SETTINGS FROM DCONF
# -----------------------------------
if [[ -f "$DCONF_SETTINGS" ]]; then
    echo "🔄 Applying GNOME settings from dconf..."
    run_cmd dconf load / < "$DCONF_SETTINGS"
    echo "✅ GNOME settings applied!"
else
    echo "⚠️ No GNOME dconf settings found."
fi

# -----------------------------------
# PACKAGE MANAGEMENT FUNCTIONS
# -----------------------------------
install_apt_package() {
    local package="$1"
    echo "📦 Installing: $package"
    if ! run_cmd sudo apt-get install -y "$package"; then
        log_error "Error installing: $package"
    else
        echo "✅ Installed: $package"
    fi
}

remove_apt_package() {
    local package="$1"
    echo "🗑 Removing: $package"
    if ! run_cmd sudo apt-get remove --purge -y "$package"; then
        log_error "Error removing: $package"
    else
        echo "✅ Removed: $package"
    fi
}

install_flatpak_package() {
    local package="$1"
    echo "📦 Installing Flatpak: $package"
    if ! run_cmd flatpak install -y flathub "$package"; then
        log_error "Error installing Flatpak package: $package"
    else
        echo "✅ Installed: $package"
    fi
}

# -----------------------------------
# PROCESS USER PACKAGE LISTS
# -----------------------------------

# Install APT packages
if [[ -f "$APT_INSTALL_LIST" ]]; then
    echo "📦 Installing user-defined APT packages..."
    while read -r pkg; do
        [[ -z "$pkg" || "$pkg" == "#"* ]] && continue  # Skip empty lines and comments
        install_apt_package "$pkg"
    done < "$APT_INSTALL_LIST"
else
    echo "⚠️ No APT install list found. Skipping..."
fi

# Remove APT packages
if [[ -f "$APT_REMOVE_LIST" ]]; then
    echo "🗑 Removing user-defined APT packages..."
    while read -r pkg; do
        [[ -z "$pkg" || "$pkg" == "#"* ]] && continue
        remove_apt_package "$pkg"
    done < "$APT_REMOVE_LIST"
else
    echo "⚠️ No APT remove list found. Skipping..."
fi

# Install Flatpak packages
if [[ -f "$FLATPAK_LIST" ]]; then
    echo "📦 Installing user-defined Flatpak applications..."
    while read -r pkg; do
        [[ -z "$pkg" || "$pkg" == "#"* ]] && continue
        install_flatpak_package "$pkg"
    done < "$FLATPAK_LIST"
else
    echo "⚠️ No Flatpak install list found. Skipping..."
fi

# -----------------------------------
# PROMPT FOR REBOOT
# -----------------------------------
read -rp "Setup complete! Reboot now? (Y/N): " REBOOT_NOW
if [[ "$REBOOT_NOW" =~ ^[Yy]$ ]]; then
    echo "🔄 Rebooting..."
    sudo reboot
else
    echo "✅ GNOME setup completed! Please reboot manually."
fi
