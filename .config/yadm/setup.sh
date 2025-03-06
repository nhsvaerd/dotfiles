#!/bin/bash

echo "Running GNOME Setup Script..."

# -----------------------------------
# 📝 USER PACKAGE LISTS
# -----------------------------------
INSTALL_APT_PACKAGES=(
    "synaptic"
    "mousetweaks"
    "gparted"
    "baobab"
    "network-manager-gnome"
    "dconf-editor"
)

REMOVE_APT_PACKAGES=(
    "nano"
    "thunderbird"
    "transmission-gtk"
    "gnome-remote-desktop"
    "gnome-games"
    "gnome-weather"
    "evolution"
    "simple-scan"
)

INSTALL_FLATPAKS=(
    "com.github.tchx84.Flatseal"
    "one.ablaze.floorp"
    "org.kde.dolphin"
)


# -----------------------------------
# 📝 PROMPT FOR DEBUG MODE
# -----------------------------------
DEBUG_LOG="$HOME/setup-gnome.log"
DEBUG_MODE=false

read -rp "Enable debug mode? (Y/N): " DEBUG_INPUT
if [[ "$DEBUG_INPUT" =~ ^[Yy]$ ]]; then
    DEBUG_MODE=true
    echo "📝 Debug mode enabled. Logging to $DEBUG_LOG"
    exec 3>&1 1>>"$DEBUG_LOG" 2>&1
    echo "========== $(date) ==========" >> "$DEBUG_LOG"
fi

# -----------------------------------
# 📦 INSTALL CORE GNOME PACKAGES
# -----------------------------------
echo "📦 Installing core GNOME packages..."
sudo apt-get update
if sudo apt-get install -y gnome-core gnome-tweaks gnome-shell-extensions gnome-shell-extension-manager pipx; then
    echo "✅ GNOME packages installed!"
else
    [[ $DEBUG_MODE == true ]] && echo "❌ Failed to install GNOME packages." >&3
fi

# -----------------------------------
# 🛠 INSTALL GNOME-EXTENSIONS-CLI
# -----------------------------------
echo "📦 Installing gnome-extensions-cli..."
if ! pipx install gnome-extensions-cli; then
    [[ $DEBUG_MODE == true ]] && echo "❌ Failed to install gnome-extensions-cli." >&3
fi

# -----------------------------------
# 🧩 INSTALL GNOME EXTENSIONS FROM LIST
# -----------------------------------
EXTENSIONS_LIST="$HOME/.config/yadm/gnome-enabled-extensions.txt"
if [[ -f "$EXTENSIONS_LIST" ]]; then
    echo "🔄 Installing GNOME extensions..."
    while read -r EXTENSION; do
        [[ -z "$EXTENSION" || "$EXTENSION" == "#"* ]] && continue  # Skip empty lines and comments
        echo "📦 Installing extension: $EXTENSION"
        if ! gnome-extensions-cli install "$EXTENSION"; then
            [[ $DEBUG_MODE == true ]] && echo "❌ Error installing: $EXTENSION" >&3
        fi
    done < "$EXTENSIONS_LIST"
    echo "✅ GNOME extensions setup complete!"
else
    echo "⚠️ No GNOME extensions list found at $EXTENSIONS_LIST. Skipping..."
fi

# -----------------------------------
# 🎨 APPLY GNOME SETTINGS FROM DCONF
# -----------------------------------
DCONF_SETTINGS="$HOME/.config/dconf/user-settings.conf"
if [[ -f "$DCONF_SETTINGS" ]]; then
    echo "🔄 Applying GNOME settings from dconf..."
    dconf load / < "$DCONF_SETTINGS"
    echo "✅ GNOME settings applied!"
else
    echo "⚠️ No GNOME dconf settings found."
fi

# -----------------------------------
# 🔧 PACKAGE MANAGEMENT FUNCTIONS
# -----------------------------------
install_apt_package() {
    local package="$1"
    echo "📦 Installing: $package"
    if sudo apt-get install -y "$package" >/dev/null 2>&1; then
        echo "✅ Installed: $package"
    else
        [[ $DEBUG_MODE == true ]] && echo "❌ Error installing: $package" >&3
    fi
}

remove_apt_package() {
    local package="$1"
    echo "🗑 Removing: $package"
    if sudo apt-get remove --purge -y "$package" >/dev/null 2>&1; then
        echo "✅ Removed: $package"
    else
        [[ $DEBUG_MODE == true ]] && echo "❌ Error removing: $package" >&3
    fi
}

install_flatpak_package() {
    local package="$1"
    echo "📦 Installing Flatpak: $package"
    if flatpak install -y flathub "$package" >/dev/null 2>&1; then
        echo "✅ Installed: $package"
    else
        [[ $DEBUG_MODE == true ]] && echo "❌ Error installing: $package" >&3
    fi
}

# -----------------------------------
# 📦 PROCESS USER PACKAGE LISTS
# -----------------------------------
echo "📦 Installing user-defined APT packages..."
for pkg in "${INSTALL_APT_PACKAGES[@]}"; do
    install_apt_package "$pkg"
done

echo "🗑 Removing user-defined APT packages..."
for pkg in "${REMOVE_APT_PACKAGES[@]}"; do
    remove_apt_package "$pkg"
done

echo "📦 Installing user-defined Flatpak applications..."
for pkg in "${INSTALL_FLATPAKS[@]}"; do
    install_flatpak_package "$pkg"
done

# -----------------------------------
# 🔄 PROMPT FOR REBOOT
# -----------------------------------
read -rp "Setup complete! Reboot now? (Y/N): " REBOOT_NOW
if [[ "$REBOOT_NOW" =~ ^[Yy]$ ]]; then
    echo "🔄 Rebooting..."
    sudo reboot
else
    echo "✅ GNOME setup completed! Please reboot manually."
fi
