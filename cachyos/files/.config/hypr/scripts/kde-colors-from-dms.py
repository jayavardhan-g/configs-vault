#!/usr/bin/env python3
"""Merge DMS's generated KDE colour scheme into ~/.config/kdeglobals.

Qt/KDE apps (Dolphin) read their colours from the [Colors:*] sections of kdeglobals,
not from the scheme file. Noctalia merges its own scheme there itself; DMS only does so
through plasma-apply-colorscheme, which isn't installed here. So while DMS is the shell,
this copies every key of DankMatugenDark.colors into kdeglobals with kwriteconfig6.

Run by kde-colors-from-dms.path whenever DMS regenerates the scheme (wallpaper change).
Does nothing unless kdeglobals is already on the DMS scheme (shell-theme.sh dms sets it),
so it can't touch Noctalia's colours.
"""
import configparser
import os
import subprocess
import sys

home = os.path.expanduser("~")
scheme = os.path.join(home, ".local/share/color-schemes/DankMatugenDark.colors")
kdeglobals = os.path.join(home, ".config/kdeglobals")


def current_scheme():
    cp = configparser.RawConfigParser(strict=False, interpolation=None)
    cp.optionxform = str
    cp.read(kdeglobals)
    return cp.get("General", "ColorScheme", fallback="")


if current_scheme() != "DankMatugenDark" or not os.path.exists(scheme):
    sys.exit(0)

src = configparser.RawConfigParser(strict=False, interpolation=None)
src.optionxform = str
src.read(scheme)
for section in src.sections():
    if section == "KDE":
        continue
    for key, value in src.items(section):
        subprocess.run(["kwriteconfig6", "--file", "kdeglobals", "--group", section, "--key", key, value], check=True)
