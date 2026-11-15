set -g fish_greeting   # fish karşılama yazısı kapalı
fish_add_path -g ~/.local/bin   # ada, ada-rofi, foot-tmux... (mango PATH'i buradan devralır)

# tty1 girişinde mango: conf.d (flatpak.fish dahil) bittikten sonra çalışsın diye burada.
# systemd'li sistemlerde oturum D-Bus'ı zaten var; yoksa (OpenRC/elogind) biz açarız.
if status is-login; and test -z "$WAYLAND_DISPLAY"; and test (tty) = /dev/tty1; and command -q mango
    if test -S "$XDG_RUNTIME_DIR/bus"
        exec mango
    else
        exec dbus-run-session mango
    end
end

if status is-interactive
    command -q starship; and starship init fish | source
    command -q fastfetch; and fastfetch
end
