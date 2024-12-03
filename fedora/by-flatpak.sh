#!/bin/bash

# Function to pause the script for a given number of seconds
pause_script() {
    echo "Pausing for $1 seconds..."
    sleep "$1"
}

# Function to remove LibreOffice
remove_libreoffice() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Removing LibreOffice                                                   #"
    echo "# -----------------------------------------------------------------------#"
    sudo dnf remove -y libreoffice*
}

# Function to install Flatpak utility and add Flathub repository
install_flatpak_and_add_flathub() {
    echo "# -----------------------------------------------------------------------#"
    echo "# Adding Flatpak utility, Repository, and Apps                           #"
    echo "# -----------------------------------------------------------------------#"
    sudo dnf install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Function to install a list of Flatpak apps
install_flatpak_apps() {
    local apps=(
        "org.videolan.VLC"
        "org.remmina.Remmina"
        "com.heroicgameslauncher.hgl"
        "com.obsproject.Studio"
        "md.obsidian.Obsidian"
        "org.blender.Blender"
        "de.haeckerfelix.Fragments"
        "org.filezillaproject.Filezilla"
        "org.gimp.GIMP"
        "org.inkscape.Inkscape"
        "org.jupyter.JupyterLab"
        "org.kicad.KiCad"
        "org.kde.kdenlive"
        "org.octave.Octave"
        "org.libreoffice.LibreOffice"
        "org.gnome.Extensions"
        "com.jeffser.Alpaca"
        "tv.kodi.Kodi"
        "com.spotify.Client"
        "com.jetbrains.PyCharm-Community"
        "io.podman_desktop.PodmanDesktop"
        "org.nickvision.tubeconverter"
        "com.calibre_ebook.calibre"
        "org.gnome.meld"
    )

    for app in "${apps[@]}"; do
        echo "---> Installing $app"
        flatpak install flathub "$app" -y
    done
}

# Main script execution
remove_libreoffice
pause_script 2

install_flatpak_and_add_flathub
pause_script 2

install_flatpak_apps
pause_script 2

echo "# -----------------------------------------------------------------------#"
echo "# Flatpak installations complete.                                        #"
echo "# -----------------------------------------------------------------------#"
