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
        "org.filezillaproject.Filezilla"
        "org.inkscape.Inkscape"
        "org.jupyter.JupyterLab"
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
        "com.usebottles.bottles"
        "org.gnome.Calendar"
        "org.gnome.baobab"
        "org.gnome.clocks"
        "com.calibre_ebook.calibre"
        "org.remmina.Remmina"
        "org.octave.Octave"
        "app.zen_browser.zen"
        "com.obsproject.Studio"
        "com.heroicgameslauncher.hgl"
        "io.github.flattool.Warehouse"
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
