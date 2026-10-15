#!/bin/sh
# Point every app's colours at the running desktop shell's generated theme.
#
#   shell-theme.sh noctalia | dms
#
# Run by autostart.lua with SHELL_NAME (config/shell.lua) at every login, so the two
# can't drift apart. Both shells regenerate their own files on wallpaper changes; this
# only flips which file each app includes. Idempotent.
#
#   app        Noctalia file                      DMS file
#   kitty      themes/noctalia.conf               dank-theme.conf     (Neovim follows kitty's include)
#   GTK 3/4    noctalia.css                       dank-colors.css     (pomodoro Theme.qml follows gtk-4.0)
#   Qt         qt6ct/colors/noctalia.conf         qt6ct/colors/matugen.conf
#   KDE        ColorScheme=Noctalia               ColorScheme=DankMatugenDark (+ kde-colors-from-dms.path)
#   btop       themes/noctalia.theme              themes/dank.theme   (~/.config/matugen/config.toml)
#   alacritty  themes/noctalia.toml               dank-theme.toml

set -eu
C="$HOME/.config"

case "${1:-}" in
    noctalia)
        kitty='include themes/noctalia.conf'
        gtk='@import url("noctalia.css");'
        qt='noctalia.conf'
        kde='Noctalia'
        btop='noctalia'
        alacritty='~/.config/alacritty/themes/noctalia.toml'
        ;;
    dms)
        kitty='include dank-theme.conf'
        gtk='@import url("dank-colors.css");'
        qt='matugen.conf'
        kde='DankMatugenDark'
        btop='dank'
        alacritty='~/.config/alacritty/dank-theme.toml'
        ;;
    *) echo "usage: $0 noctalia|dms" >&2; exit 2 ;;
esac

sed -i -E "s#^include (themes/noctalia\.conf|dank-theme\.conf)\$#$kitty#" "$C/kitty/kitty.conf"
for v in 3.0 4.0; do
    sed -i -E "s#^@import url\(\"(noctalia|dank-colors)\.css\"\);\$#$gtk#" "$C/gtk-$v/gtk.css"
done
sed -i -E "s#^(color_scheme_path=.*/qt6ct/colors/)(noctalia|matugen)\.conf\$#\1$qt#" "$C/qt6ct/qt6ct.conf"
kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$kde"
sed -i -E "s#^color_theme = \"(noctalia|dank)\"\$#color_theme = \"$btop\"#" "$C/btop/btop.conf"
sed -i -E "s#^import = \[\"[^\"]*(noctalia\.toml|dank-theme\.toml)\"\]\$#import = [\"$alacritty\"]#" "$C/alacritty/alacritty.toml"

# Under DMS, pull its current KDE colours into kdeglobals right away (later wallpaper
# changes are picked up by kde-colors-from-dms.path).
[ "$1" = dms ] && "$HOME/.config/hypr/scripts/kde-colors-from-dms.py" || true

# Running kitty windows re-read kitty.conf on SIGUSR1.
pkill -USR1 -x kitty || true
