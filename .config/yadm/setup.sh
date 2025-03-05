#!/bin/bash

echo "Running GNOME Setup Script..."

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
    gnome-shell-extensions
    gnome-shell-extension-manager
    gnome-software-plugin-flatpak
    pipx
)

# 🚀 Fetch all GNOME packages in parallel
echo "📦 Fetching GNOME packages..."
printf "%s\n" "${GNOME_PACKAGES[@]}" | xargs -P 8 -I{} sudo apt-get install -y --download-only {}

# 🚀 Install GNOME packages in parallel
echo "🚀 Installing GNOME packages..."
printf "%s\n" "${GNOME_PACKAGES[@]}" | xargs -P 8 -I{} sudo apt install -y {}

# Ensure pipx is set up
pipx ensurepath
export PATH=$HOME/.local/bin:$PATH  # Ensure pipx-installed CLI tools are available

# Install gnome-extensions-cli via pipx if missing
if ! command -v gnome-extensions-cli &>/dev/null; then
    echo "📦 Installing gnome-extensions-cli..."
    pipx install gnome-extensions-cli
fi

# Function to install APT packages from `packages.json`
install_apt_packages() {
    local package_list
    package_list=$(jq -r '."add-packages"."apt" // [] | .[].name' "$HOME/.config/yadm/packages.json")

    if [[ -n "$package_list" ]]; then
        echo "🚀 Installing additional APT packages..."
        printf "%s\n" "$package_list" | xargs -P 8 -I{} sudo apt install -y {}

        echo "✅ APT installation completed!"
    else
        echo "⚠️ No additional APT packages to install."
    fi
}

# Function to install Flatpak packages from `packages.json`
install_flatpak_packages() {
    while IFS= read -r name; do
        remote=$(jq -r --arg name "$name" '."add-packages"."flatpak"[] | select(.name == $name) | .remote // "flathub"' "$HOME/.config/yadm/packages.json")
        if [[ -n "$name" ]]; then
            echo "📦 Installing Flatpak: $name from $remote"
            flatpak install -y "$remote" "$name" || {
                echo "❌ Failed to install Flatpak package: $name"
                return 1
            }
        fi
    done < <(jq -r '."add-packages"."flatpak" // [] | .[].name' "$HOME/.config/yadm/packages.json")
}

# Process user-defined package list
if [ -f "$HOME/.config/yadm/packages.json" ]; then
    install_apt_packages
    install_flatpak_packages
else
    echo "⚠️ No packages.json file found for this branch."
fi

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
    echo "✅ GNOME setup completed! Reboot to apply all changes"
fi
