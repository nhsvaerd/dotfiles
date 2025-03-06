#!/bin/bash

echo "Running GNOME Setup Script..."

# -----------------------------------
# 📝 DEFINE USER PACKAGE LISTS
# -----------------------------------
INSTALL_APT_PACKAGES=(
    "htop"
    "vim"
    "curl"
    "neofetch"
)

REMOVE_APT_PACKAGES=(
    "nano"
    "thunderbird"
)

INSTALL_FLATPAKS=(
    "com.github.tchx84.Flatseal"
    "org.libreoffice.LibreOffice"
)

# -----------------------------------
# 📝 PROMPT FOR DEBUG MODE
# -----------------------------------
DEBUG_LOG="$HOME/setup-gnome.log"
DEBUG_MODE=false

read -rp "Enable debug mode? (Y/N): " DEBUG_INPUT
if [[ "$DEBUG_INPUT" =~ ^[Yy]$ ]]; then
    DEBUG_MODE=true
    echo "📝 Debug mode enabled. Logging errors to $DEBUG_LOG"
    echo "========== $(date) ==========" >> "$DEBUG_LOG"
fi

# Function to log errors only if debug mode is enabled
log_error() {
    if [[ $DEBUG_MODE == true ]]; then
        echo "❌ $1" | tee -a "$DEBUG_LOG" >&2
    else
        echo "❌ $1" >&2
    fi
}

# -----------------------------------
# 📦 INSTALL CORE GNOME PACKAGES
# -----------------------------------
echo "📦 Installing core GNOME packages..."
sudo apt-get update
if ! sudo apt-get install -y gnome-core gnome-tweaks gnome-shell-extensions gnome-shell-extension-manager pipx; then
    log_error "Failed to install GNOME packages."
fi

# -----------------------------------
# 🛠 INSTALL GNOME-EXTENSIONS-CLI (Verify Installation)
# -----------------------------------
echo "📦 Installing gnome-extensions-cli..."
if ! command -v gnome-extensions-cli &>/dev/null; then
    if ! pipx install gnome-extensions-cli; then
        log_error "Failed to install gnome-extensions-cli."
    fi
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
            log_error "Error installing GNOME extension: $EXTENSION"
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
# 🔧 ENSURE FLATHUB IS CONFIGURED BEFORE INSTALLING FLATPAKS
# -----------------------------------
if ! flatpak remote-list | grep -q "flathub"; then
    echo "📦 Adding Flathub remote..."
    if ! flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        log_error "Failed to add Flathub remote."
    fi
fi

# -----------------------------------
# 🔧 PACKAGE MANAGEMENT FUNCTIONS
# -----------------------------------
install_apt_package() {
    local package="$1"
    echo "📦 Installing: $package"
    if ! sudo apt-get install -y "$package"; then
        log_error "Error installing: $package"
    else
        echo "✅ Installed: $package"
    fi
}

remove_apt_package() {
    local package="$1"
    echo "🗑 Removing: $package"
    if ! sudo apt-get remove --purge -y "$package"; then
        log_error "Error removing: $package"
    else
        echo "✅ Removed: $package"
    fi
}

install_flatpak_package() {
    local package="$1"
    echo "📦 Installing Flatpak: $package"
    if ! flatpak install -y flathub "$package"; then
        log_error "Error installing Flatpak package: $package"
    else
        echo "✅ Installed: $package"
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
    echo "✅ GNOME setup complete. Please reboot manually."
fi
