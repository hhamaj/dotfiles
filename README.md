# dotfiles

MangoWC desktop with [ada](https://github.com/hhamaj/ada), a native island
bar written in C, as the bar, notification daemon and tray. Monochrome
macOS-dark theme across mango, foot, tmux, rofi, GTK and Qt.

Works on Arch and Gentoo (OpenRC/elogind or systemd); other distros only
need the packages installed by hand.

## Install

```sh
git clone --recurse-submodules https://github.com/hhamaj/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh --deps --fonts
```

| Flag | Does |
|---|---|
| (none) | link configs and scripts, build and install ada to `~/.local` |
| `--deps` | install packages; asks group by group (`y` whole group, `n` skip, `p` pick packages one by one, already installed ones marked) |
| `--groups=build,session` | install those groups without asking (`all` for every group) |
| `--list-groups` | show the groups and their packages for this distro |
| `--fonts` | download MesloLGS and GeistMono Nerd Fonts to `~/.local/share/fonts` |
| `--no-ada` | skip building ada |
| `--dry-run` | print what would happen |

Package groups live in `packages/arch.txt` and `packages/gentoo.txt`
(`build`, `session`, `apps`, `look`); add a `[name] description` line to make
a new one. On Arch everything comes from the official repos; `aur:<pkg>` entries, if you
add any, go through paru or yay.
Gentoo needs the GURU overlay.

Each file is symlinked on its own, so editing `~/.config/foot/foot.ini`
edits the repo. Anything already in place is moved to
`*.bak-dotfiles-<date>`. Running it again is safe.

Then set fish as your login shell (`chsh -s /usr/bin/fish`) and log in on
tty1: mango starts by itself. Or run `mango` from a tty.

## Per machine

`~/.config/mango/local.conf` is created from
`config/mango/local.conf.example` and is not tracked. Put monitors, keyboard
layout and anything else machine-specific there:

```
monitor_rule=name:^HDMI-A-1$,width:1920,height:1080,refresh:180.003,x:0,y:0
```

The wallpaper is the `~/.config/mango/wallpaper` symlink, set with
SUPER+Shift+w from `~/Pictures/wallpapers` (or `$WALLPAPER_DIR`). Without it
the background is plain `#0d0d0e`.

## Layout

```
config/     -> ~/.config         (files ending in .in are copied with @HOME@ filled in)
bin/        -> ~/.local/bin
ada/        ada bar (git submodule), built into ~/.local/bin
packages/   package lists per distro
```

| Config | |
|---|---|
| mango | compositor; starts ada, cliphist, swaybg, swayidle |
| rofi | launcher, clipboard and wallpaper menus (open inside ada via `ada-rofi`) |
| foot + tmux | terminal; tmux windows act as tabs (`foot-tmux`, SUPER+q asks before closing busy ones) |
| fish, starship, fastfetch | shell |
| swaylock | lock screen with blurred wallpaper |
| gtk-3.0/4.0, qt5ct/qt6ct, Kvantum, fontconfig | theming |
| mako | notifications if ada isn't running |
| nvim, btop, cava | apps |

## Keys

| Key | |
|---|---|
| SUPER+Return | terminal |
| SUPER+d | launcher (inside ada) |
| SUPER+Shift+v | clipboard history |
| SUPER+Shift+w | wallpaper |
| SUPER+Shift+s / Print | screenshot region to clipboard / full to `~/Pictures/Screenshots` |
| SUPER+q / SUPER+Shift+q | close / force kill |
| SUPER+Ctrl+q | lock |
| SUPER+Shift+e | quit mango |
| SUPER+o | overview |
| SUPER+v / s / w / n | dwindle / monocle / scroller / next layout |
| SUPER+1..9, SUPER+Shift+1..9 | workspace / move window |
| SUPER+r | resize mode |

## Not packaged

These are referenced by the configs but must be installed by hand; things
still work without them, just with default looks:

- GTK/Kvantum theme **Monochrome**, icon theme **WhiteSur**, cursor **DMZ-White**
- **Inter Nerd Font** (falls back to plain Inter through `fontconfig/conf.d/50-dotfiles.conf`)

## Updating ada

```sh
git submodule update --remote ada && ./install.sh
```
