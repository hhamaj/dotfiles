#!/bin/sh
# Pano geçmişi (cliphist). Kopyalananları mango açılışındaki
# `wl-paste --watch cliphist store` kaydeder; seçilen öğe tekrar panoya kopyalanır.
# ada açıksa menü adanın içinde açılır (ada-rofi), değilse düz rofi.
sel=$(cliphist list | "$HOME/.local/bin/ada-rofi" 520 374 -dmenu -i -p "" -display-columns 2 -no-show-icons \
  -theme-str 'entry { placeholder: "Pano geçmişinde ara"; } element-text { markup: false; }') || exit 0

[ -n "$sel" ] && printf '%s' "$sel" | cliphist decode | wl-copy
