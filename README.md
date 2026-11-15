# My personal dotfiles

Feel free to explore and adapt them for your own use.

Layout:

- `.zshrc`: installed into `~`.
- `atuin/`: my Atuin config and theme, never installed. Atuin writes its own
  config at install time; compare it with this one by hand.
- `config/`: copied into `~/.config`.
- `fedora/`: post-install scripts; see `fedora/Fedora-Config-Guide.md`.
- `tools/`: helper scripts.

To use these dotfiles:

1. Clone this repository to your home directory:
   `git clone https://github.com/andrerclaudio/dotfiles.git ~/dotfiles`
2. Review the files; the scripts replace `~/.zshrc` and files in `~/.config`.
3. Set your own name and email in `fedora/core.sh` (`GIT_USER_NAME`,
   `GIT_USER_EMAIL`); it writes them to your global git config.
4. Follow `fedora/Fedora-Config-Guide.md`.

License:

- This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.
