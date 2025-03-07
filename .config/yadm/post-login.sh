#!/bin/bash

echo "🚀 Running Post-Login GNOME Setup..."

# -----------------------------------
# 📝 VERIFY GNOME SHELL SESSION
# -----------------------------------
if ! pgrep -x "gnome-shell" >/dev/null; then
    echo "❌ GNOME Shell is not running! Log into GNOME before running this script."
    exit 1
fi

# Ensure `DBus` session is available
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

# -----------------------------------
# 🔍 Get the current list of installed GNOME extensions
# -----------------------------------
EXTENSIONS_LIST="$HOME/.config/gnome-enabled-extensions.txt"
CURRENT_EXTENSIONS=$(gnome-extensions list)

if [[ ! -f "$EXTENSIONS_LIST" ]]; then
    echo "⚠️ No GNOME extensions list found. Skipping cleanup."
else
    echo "🔄 Cleaning up GNOME extensions..."

    # Read the repo's extension list into an array
    mapfile -t REPO_EXTENSIONS < "$EXTENSIONS_LIST"

    for EXT in $CURRENT_EXTENSIONS; do
        if [[ ! " ${REPO_EXTENSIONS[@]} " =~ " $EXT " ]]; then
            if [[ -d "/usr/share/gnome-shell/extensions/$EXT" ]]; then
                echo "🔹 Disabling system extension: $EXT"
                gnome-extensions disable "$EXT"
            else
                echo "❌ Removing unlisted user-installed extension: $EXT"
                gnome-extensions disable "$EXT"
                gnome-extensions uninstall "$EXT"
            fi
        fi
    done
fi

# -----------------------------------
# 🧩 INSTALL MISSING GNOME EXTENSIONS
# -----------------------------------
if [[ -f "$EXTENSIONS_LIST" ]]; then
    echo "🔄 Installing missing GNOME extensions..."
    while read -r EXTENSION; do
        [[ -z "$EXTENSION" || "$EXTENSION" == "#"* ]] && continue  # Skip empty lines and comments
        if gnome-extensions list | grep -q "$EXTENSION"; then
            echo "✅ Already installed: $EXTENSION"
            gnome-extensions enable "$EXTENSION"
        else
            echo "⚠️ Installing missing extension: $EXTENSION"
            if gnome-extensions-cli install "$EXTENSION"; then
                echo "✅ Installed and enabled: $EXTENSION"
                gnome-extensions enable "$EXTENSION"
            else
                echo "❌ Error installing $EXTENSION. It may not be available."
            fi
        fi
    done < "$EXTENSIONS_LIST"
    echo "✅ GNOME extensions setup complete!"
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
# 🔄 CLEAN UP: REMOVE POST-LOGIN SCRIPT
# -----------------------------------
echo "🗑 Removing post-login script from autostart..."
rm -f "$HOME/.config/autostart/post-login.desktop"

echo "✅ GNOME setup completed!"
