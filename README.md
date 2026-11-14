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

- Clone this repository to your home directory:
  `git clone https://github.com/andrerclaudio/dotfiles.git ~/dotfiles`
- Set your own name and email in `fedora/core.sh` (`GIT_USER_NAME`,
  `GIT_USER_EMAIL`) first: it writes them to your global git config
- Follow `fedora/Fedora-Config-Guide.md`
- Review the files and customize them as you please

License:

- This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.
