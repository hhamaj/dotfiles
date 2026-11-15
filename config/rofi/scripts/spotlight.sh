#!/bin/sh
# Spotlight: uygulamalar + hesap makinesi aynı pencerede.
# Tab / Shift+Tab: Uygulamalar <-> Hesap makinesi (yazılan metin korunur).
# Hesap modunda Enter sonucu panoya kopyalar. rofi-calc kurulu değilse sadece uygulamalar.
if rofi -help 2>/dev/null | grep -q '• calc'; then
  exec "$HOME/.local/bin/ada-rofi" 520 374 -show drun -modes "drun,calc" \
    -kb-row-tab "" -kb-element-next "" -kb-element-prev "" \
    -kb-mode-next "Tab" -kb-mode-previous "ISO_Left_Tab" \
    -no-history -calc-command "echo -n '{result}' | wl-copy" \
    -hint-welcome "" "$@"
else
  # Eklenti yokken de Tab uygulamalar arasında gezinmesin (rebuild sonrası hesap moduna geçer)
  exec "$HOME/.local/bin/ada-rofi" 520 374 -show drun -kb-row-tab "" -kb-element-next "" -kb-element-prev "" "$@"
fi
