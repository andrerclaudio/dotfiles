# This repository contains my personal dotfiles. Feel free to explore and adapt them for your own use

Layout:

- `.zshrc` — installed into `~` as-is. Dotfiles the shell or program reads
  straight from `~` live at the repo root, never under `config/`. The installer
  keeps the file it replaces as `~/.zshrc.bak`.
- `atuin/` — my Atuin config and theme, never installed. Atuin writes its own
  config at install time; compare it with this one by hand.
- `config/` — copied verbatim into `~/.config`. Only put things here that belong
  under `~/.config`.
- `fedora/` — post-install scripts, run in order: `core.sh` → `apps.sh` →
  `extra.sh` → `desktop.sh`, with `lib.sh` holding what the four share. See
  `fedora/Fedora-Config-Guide.md`.
- `tools/` — standalone helper scripts, not part of the install flow.
  The exceptions: `core.sh` also runs `change_swap.sh` and `colors_solid.py`,
  and `extra.sh` runs `gnome_app_grid.sh` as its last step.

To use these dotfiles:

- Clone this repository to your home directory:
  `git clone https://github.com/andrerclaudio/dotfiles.git ~/dotfiles`
- Set your own name and email in `fedora/core.sh` (`GIT_USER_NAME`,
  `GIT_USER_EMAIL`) first: it writes them to your global git config
- Follow `fedora/Fedora-Config-Guide.md`
- Review the files and customize them as you please

License:

- This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.
