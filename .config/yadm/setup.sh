#!/bin/bash

echo "🚀 Running GNOME Setup Script..."

# Prompt for debug mode
read -rp "Enable debug mode? (Y/N): " DEBUG_MODE
DEBUG_LOG="$HOME/setup-gnome.log"

if [[ "$DEBUG_MODE" =~ ^[Yy]$ ]]; then
    echo "📝 Debug mode enabled. Logging to $DEBUG_LOG"
    exec > >(tee -a "$DEBUG_LOG") 2>&1
    echo "========== $(date) ==========" >> "$DEBUG_LOG"
fi

# Define GNOME package list
GNOME_PACKAGES=(
    gnome-core
    gnome-tweaks
    gnome-shell-extensions
    gnome-shell-extension-manager
    pipx
)

# 🚀 Install GNOME packages (SEQUENTIALLY to prevent dpkg lock issues)
echo "📦 Installing GNOME packages..."
for package in "${GNOME_PACKAGES[@]}"; do
    sudo apt install -y "$package"
done
echo "✅ GNOME installation completed!"

# Install gnome-extensions-cli via pipx
echo "📦 Installing gnome-extensions-cli..."
pipx install gnome-extensions-cli

# Validate JSON format before proceeding with package installation
PACKAGE_FILE="$HOME/.config/yadm/packages.json"
if ! jq . "$PACKAGE_FILE" >/dev/null 2>&1; then
    echo "❌ Error: Invalid JSON format in packages.json"
    exit 1
fi

# Function to install APT packages from `packages.json`
install_apt_packages() {
    local package_list
    package_list=$(jq -r '."add-packages"."apt" // [] | .[].name' "$PACKAGE_FILE")

    if [[ -n "$package_list" ]]; then
        echo "📦 Installing additional APT packages..."
        for pkg in $package_list; do
            sudo apt install -y "$pkg"
        done
        echo "✅ APT installation completed!"
    else
        echo "⚠️ No additional APT packages to install."
    fi
}

# Function to install Flatpak packages from `packages.json`
install_flatpak_packages() {
    while IFS= read -r name; do
        remote=$(jq -r --arg name "$name" '."add-packages"."flatpak"[] | select(.name == $name) | .remote // "flathub"' "$PACKAGE_FILE")
        if [[ -n "$name" ]]; then
            echo "📦 Installing Flatpak: $name from $remote"
            flatpak install -y "$remote" "$name"
        fi
    done < <(jq -r '."add-packages"."flatpak" // [] | .[].name' "$PACKAGE_FILE")
}

# Process user-defined package list
install_apt_packages
install_flatpak_packages

# Apply GNOME settings from dconf
if [ -f "$HOME/.config/dconf/user-settings.conf" ]; then
    echo "🔄 Applying GNOME settings from dconf..."
    dconf load / < "$HOME/.config/dconf/user-settings.conf"
    echo "✅ GNOME settings applied!"
else
    echo "⚠️ No GNOME dconf settings found."
fi

# Prompt for reboot
read -rp "Setup complete! Reboot now? (Y/N): " REBOOT_NOW
if [[ "$REBOOT_NOW" =~ ^[Yy]$ ]]; then
    echo "🔄 Rebooting..."
    sudo reboot
else
    echo "✅ GNOME setup completed! Please reboot manually."
fi
