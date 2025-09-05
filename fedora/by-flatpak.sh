#!/bin/bash

# Function to pause the script for a given number of seconds
pause_script() {
    echo "Pausing for $1 seconds..."
    sleep "$1"
}

# Function to install a list of Flatpak apps
install_flatpak_apps() {
    local apps=(
        "org.videolan.VLC"
        "org.filezillaproject.Filezilla"
        "org.inkscape.Inkscape"
        "org.kde.kdenlive"
        "org.libreoffice.LibreOffice"
        "com.jeffser.Alpaca"
        "com.jeffser.Alpaca.Plugins.Ollama"
        "com.spotify.Client"
        "org.gnome.meld"
        "org.gnome.GHex"
        "org.gnome.Boxes"
        "com.mattjakeman.ExtensionManager"
        "org.gnome.Calculator"
        "org.gnome.TextEditor"
        "org.gnome.Evince"
        "org.gnome.font-viewer"
        "org.gnome.Characters"
        "org.gnome.Loupe"
        "org.gnome.Logs"
        "org.fedoraproject.MediaWriter"
        "org.gnome.Calendar"
        "org.gnome.baobab"
        "org.gnome.clocks"
        "org.remmina.Remmina"
        "org.octave.Octave"
        "org.kicad.KiCad"
        "com.ranfdev.DistroShelf"
        "io.github.flattool.Warehouse"
        "org.blender.Blender"
    )

    for app in "${apps[@]}"; do
        echo "---> Installing $app"
        flatpak install flathub "$app" -y
    done
}

# Main script execution
install_flatpak_apps
pause_script 2

echo "# -----------------------------------------------------------------------#"
echo "# Flatpak installations complete.                                        #"
echo "# -----------------------------------------------------------------------#"
