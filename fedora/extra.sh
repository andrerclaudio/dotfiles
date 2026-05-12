#!/bin/bash

# Pre-authenticate sudo
sudo -v

echo "# -----------------------------------------------------------------------#"
echo "# Starting Extra Configurations & Installations                          #"
echo "# -----------------------------------------------------------------------#"

# 1. Install ZSH Plugins
echo "---> Installing ZSH Plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM}/plugins/zsh-autocomplete
git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git ${ZSH_CUSTOM}/plugins/autoupdate

# 2. Install Nerd Fonts
echo "---> Installing JetBrainsMono Nerd Font..."
mkdir -p ~/Downloads/JetBrainsMono
curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
tar -xvf JetBrainsMono.tar.xz -C ~/Downloads/JetBrainsMono
mkdir -p ~/.fonts
mv ~/Downloads/JetBrainsMono ~/.fonts/
rm JetBrainsMono.tar.xz

# 3. Install Rust & Cargo Apps (Unattended)
echo "---> Installing Rust and Cargo utilities..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
cargo install tock eza pueue dysk ripgrep cargo-update

# 4. Install Zoxide & Atuin
echo "---> Installing Zoxide and Atuin..."
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# 5. Configure Eza Theme
echo "---> Configuring Eza Gruvbox theme..."
mkdir -p ~/.config/eza
git clone https://github.com/eza-community/eza-themes.git ~/.config/eza/eza-themes
ln -sf ~/.config/eza/eza-themes/themes/gruvbox-dark.yml ~/.config/eza/theme.yml

# 6. Gruvbox Plus Icon Pack
echo "---> Installing Gruvbox Icons..."
mkdir -p ~/.icons
mkdir -p ~/Documents
git clone https://github.com/SylEleuth/gruvbox-plus-icon-pack.git ~/Documents/gruvbox-plus-icon-pack
ln -s ~/Documents/gruvbox-plus-icon-pack/Gruvbox-Plus-Dark ~/.icons/Gruvbox-Plus-Dark

# 7. Install Repo tool
echo "---> Installing Google Repo Tool..."
mkdir -p ~/.local/bin
curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/.local/bin/repo
chmod a+x ~/.local/bin/repo

echo "# -----------------------------------------------------------------------#"
echo "# Extra scripts installed successfully!                                  #"
echo "# -----------------------------------------------------------------------#"