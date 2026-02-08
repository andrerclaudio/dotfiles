#!/usr/bin/env python3

"""
colors_solid.py
Generates solid-color PNG images for every unique color in the Gruvbox DARK and LIGHT palettes.

For each hex color defined in the palettes, the script:
- Normalizes and deduplicates all hex codes across both palettes.
- Converts each hex code into its RGB equivalent.
- Creates a solid-color image of size SIZE_W × SIZE_H (default: 1440×3120).
- Saves each image as "<hex>_<width>-<height>.png" (e.g., "d65d0e_1440-3120.png").

Useful for quickly generating wallpaper backgrounds, color swatches, or visual references
of the Gruvbox theme in both dark and light variants.

Pallets link:
https://github.com/morhetz/gruvbox

Requires: Pillow (install with `python3 -m pip install pillow`)
"""

from __future__ import annotations

from pathlib import Path
from typing import Dict, Iterable, Set, Tuple

from PIL import Image

# ------------------------------ Palettes ------------------------------------ #
DARK: Dict[str, str] = {
    "bg": "282828",
    "red": "cc241d",
    "green": "98971a",
    "yellow": "d79921",
    "blue": "458588",
    "purple": "b16286",
    "aqua": "689d6a",
    "gray": "a89984",
    "gray_alt": "928374",
    "red_alt": "fb4934",
    "green_alt": "b8bb26",
    "yellow_alt": "fabd2f",
    "blue_alt": "83a598",
    "purple_alt": "d3869b",
    "aqua_alt": "8ec07c",
    "fg": "ebdbb2",
    "bg0_h": "1d2021",
    "bg0": "282828",
    "bg1": "3c3836",
    "bg2": "504945",
    "bg3": "665c54",
    "bg4": "7c6f64",
    "bg0_s": "32302f",
    "fg4": "a89984",
    "fg3": "bdae93",
    "fg2": "d5c4a1",
    "fg1": "ebdbb2",
    "fg0": "fbf1c7",
    "orange": "fe8019",
    "orange_alt": "d65d0e",
}

LIGHT: Dict[str, str] = {
    "bg": "fbf1c7",
    "red": "cc241d",
    "green": "98971a",
    "yellow": "d79921",
    "blue": "458588",
    "purple": "b16286",
    "aqua": "689d6a",
    "gray": "7c6f64",
    "gray_alt": "928374",
    "red_alt": "9d0006",
    "green_alt": "79740e",
    "yellow_alt": "b57614",
    "blue_alt": "076678",
    "purple_alt": "8f3f71",
    "aqua_alt": "427b58",
    "fg": "3c3836",
    "bg0_h": "f9f5d7",
    "bg0": "fbf1c7",
    "bg1": "ebdbb2",
    "bg2": "d5c4a1",
    "bg3": "bdae93",
    "bg4": "a89984",
    "bg0_s": "f2e5bc",
    "fg4": "7c6f64",
    "fg3": "665c54",
    "fg2": "504945",
    "fg1": "3c3836",
    "fg0": "282828",
    "orange": "af3a03",
    "orange_alt": "d65d0e",
}

# ------------------------------ Image Size ---------------------------------- #
SIZE_W: int = 1440
SIZE_H: int = 3120


# ------------------------------ Helpers ------------------------------------- #
def normalize_hex(hex_str: str) -> str:
    """
    Normalize a hex color to a lowercase 6-digit string without '#'.
    Raises ValueError for invalid inputs.
    """
    s = hex_str.strip().lstrip("#").lower()
    if len(s) != 6 or any(c not in "0123456789abcdef" for c in s):
        raise ValueError(f"Invalid 6-hex color: {hex_str!r}")
    return s


def hex_to_rgb(hex6: str) -> Tuple[int, int, int]:
    """
    Convert a normalized 6-hex string (e.g., 'aabbcc') to an (R, G, B) tuple.
    """
    return (int(hex6[0:2], 16), int(hex6[2:4], 16), int(hex6[4:6], 16))


def unique_hex_values(palettes: Iterable[Dict[str, str]]) -> Set[str]:
    """
    Collect unique normalized hex values from all provided palettes.
    """
    uniques: Set[str] = set()
    for pal in palettes:
        for value in pal.values():
            uniques.add(normalize_hex(value))
    return uniques


def generate_rect(hex6: str, size: Tuple[int, int]) -> Path:
    """
    Create a solid-color PNG of given size filled with hex6 and save it as '<hex6>.png'.
    Returns the output file path.
    """
    rgb = hex_to_rgb(hex6)
    img = Image.new("RGB", size, rgb)
    out_path = Path(f"{hex6}_{SIZE_W}-{SIZE_H}.png")
    img.save(out_path, format="PNG")
    return out_path


# ---------------------------------------------------------------------------- #


def main() -> None:
    """
    Entry point: generate one PNG per unique hex across DARK and LIGHT.
    """
    size: Tuple[int, int] = (SIZE_W, SIZE_H)
    colors: Set[str] = unique_hex_values([DARK, LIGHT])

    generated: int = 0
    for hex6 in sorted(colors):
        out = generate_rect(hex6, size)
        print(f"Wrote {out} ({size[0]}x{size[1]})")
        generated += 1

    print(f"Done. Generated {generated} file(s).")


if __name__ == "__main__":
    main()
