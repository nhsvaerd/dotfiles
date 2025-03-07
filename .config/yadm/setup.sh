#!/bin/bash

echo "🚀 Running GNOME Setup Script..."

# -----------------------------------
# 📝 REQUIRE ROOT PERMISSIONS
# -----------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
    echo "❌ This script must be run as root. Use: sudo $0"
    exit 1
fi

# -----------------------------------
# 📦 INSTALL CORE GNOME PACKAGES
# -----------------------------------
echo "📦 Installing GNOME and essential packages..."
apt-get update
apt-get install -y gnome-core gnome-tweaks gnome-shell-extensions gnome-shell-extension-manager pipx

# -----------------------------------
# 📦 PROCESS APT PACKAGE LISTS
# -----------------------------------
APT_INSTALL_LIST="$HOME/.config/yadm/apt-install.txt"
APT_REMOVE_LIST="$HOME/.config/yadm/apt-remove.txt"

if [[ -f "$APT_INSTALL_LIST" ]]; then
    echo "📦 Installing additional APT packages..."
    grep -v '^#' "$APT_INSTALL_LIST" | while read -r package; do
        [[ -z "$package" ]] && continue
        apt-get install -y "$package"
    done
fi

if [[ -f "$APT_REMOVE_LIST" ]]; then
    echo "🗑 Removing APT packages..."
    grep -v '^#' "$APT_REMOVE_LIST" | while read -r package; do
        [[ -z "$package" ]] && continue
        apt-get remove --purge -y "$package"
    done
fi

# -----------------------------------
# 🛠 INSTALL GNOME-EXTENSIONS-CLI
# -----------------------------------
echo "📦 Installing gnome-extensions-cli..."
pipx install gnome-extensions-cli

# -----------------------------------
# 🔄 SETUP AUTOSTART SCRIPT FOR POST-LOGIN CONFIGURATION
# -----------------------------------
AUTOSTART_DIR="$HOME/.config/autostart"
POST_LOGIN_SCRIPT="$HOME/.config/yadm/post-login.sh"

mkdir -p "$AUTOSTART_DIR"

# Create autostart .desktop file
cat <<EOF > "$AUTOSTART_DIR/post-login.desktop"
[Desktop Entry]
Type=Application
Exec=$POST_LOGIN_SCRIPT
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Post-Login Setup
Comment=Finishing GNOME setup after user login
EOF

# Ensure post-login script exists
cat <<'EOF' > "$POST_LOGIN_SCRIPT"
#!/bin/bash
"$HOME/.config/yadm/post-login.sh"
EOF
chmod +x "$POST_LOGIN_SCRIPT"

echo "✅ GNOME installed! Please log out and log back into GNOME to complete the setup."
