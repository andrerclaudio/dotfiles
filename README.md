# This repository contains my personal dotfiles. Feel free to explore and adapt them for your own use

Layout:

- `.zshrc` — installed into `~` as-is. Dotfiles the shell or program reads
  straight from `~` live at the repo root, never under `config/`. The installer
  keeps the file it replaces as `~/.zshrc.bak`.
- `config/` — copied verbatim into `~/.config`. Only put things here that belong
  under `~/.config`.
- `fedora/` — post-install scripts, run in order: `core.sh` → `apps.sh` →
  `extra.sh`, with `lib.sh` holding what the three share. See
  `fedora/Fedora-Config-Guide.md`.
- `tools/` — standalone helper scripts and notes, not part of the install flow.

To use these dotfiles:

- Clone this repository to your home directory
- Review the files and customize them as you please

License:

- This project is licensed under the GNU General Public License v3.0. See the LICENSE file for details.
