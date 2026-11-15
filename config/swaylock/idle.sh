#!/bin/sh
# Boşta kalınca: 5 dk -> kilit, uyku öncesi -> kilit
# Hem mango hem sway'de çalışır
LOCK="$HOME/.config/swaylock/lock.sh"
exec swayidle -w \
  timeout 300 "$LOCK" \
  before-sleep "$LOCK"
