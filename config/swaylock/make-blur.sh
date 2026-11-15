#!/bin/sh
# Bulanık kilit ekranı arka planını üret: Pillow varsa make-blur.py, yoksa ImageMagick.
# İkisi de yoksa lock.sh düz koyu renkle kilitler.
WALL=$(readlink -f "$HOME/.config/mango/wallpaper")
OUT="$HOME/.cache/lockscreen.png"
[ -f "$WALL" ] || exit 1
mkdir -p "$HOME/.cache"
if python3 -c 'import PIL' 2>/dev/null; then
  exec python3 -I "$HOME/.config/swaylock/make-blur.py" "$WALL" "$OUT"
elif command -v magick >/dev/null; then
  exec magick "$WALL" -resize 1920x1080^ -gravity center -extent 1920x1080 \
    -scale 25% -blur 0x12 -resize 400% -brightness-contrast -55x0 "$OUT"
fi
exit 1
