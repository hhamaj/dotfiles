#!/bin/sh
# macOS tarzı kilit ekranı: bulanık + koyu duvar kâğıdı, sade halka göstergesi
IMG="$HOME/.cache/lockscreen.png"
WALL="$HOME/.config/mango/wallpaper"

# Bulanık arka plan yoksa ya da duvar kâğıdı değiştiyse arka planda yeniden üret;
# bu sefer düz koyu renkle kilitle (kilitleme gecikmesin)
if [ ! -f "$IMG" ] || [ "$(readlink -f "$WALL")" -nt "$IMG" ]; then
  "$HOME/.config/swaylock/make-blur.sh" &
fi
if [ -f "$IMG" ]; then BG="-i $IMG -s fill"; else BG="-c 0d0d0e"; fi

exec swaylock -f -e -F -l $BG \
  --font Inter --font-size 22 \
  --indicator-radius 80 --indicator-thickness 5 --indicator-idle-visible \
  --inside-color 0d0d0e66 --inside-clear-color 0d0d0e66 --inside-ver-color 0d0d0e99 \
  --inside-wrong-color 0d0d0e99 --inside-caps-lock-color 0d0d0e66 \
  --ring-color ffffff33 --ring-clear-color ffffff66 --ring-ver-color ffffffcc \
  --ring-wrong-color ff453aff --ring-caps-lock-color ff9f0aaa \
  --key-hl-color ffffffdd --bs-hl-color ff453aff \
  --caps-lock-key-hl-color ff9f0aff --caps-lock-bs-hl-color ff453aff \
  --line-color 00000000 --line-clear-color 00000000 --line-ver-color 00000000 \
  --line-wrong-color 00000000 --line-caps-lock-color 00000000 \
  --separator-color 00000000 \
  --text-color f2f2f2 --text-clear-color f2f2f2 --text-ver-color f2f2f2 \
  --text-wrong-color ff453a --text-caps-lock-color ff9f0a
