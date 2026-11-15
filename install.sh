#!/usr/bin/env bash
# Links these dotfiles into $HOME and builds ada.
#
#   ./install.sh            link configs + scripts, build and install ada
#   ./install.sh --deps     also install packages (Arch or Gentoo)
#   ./install.sh --fonts    also download MesloLGS + GeistMono Nerd Fonts
#   ./install.sh --no-ada   skip building ada
#   ./install.sh --dry-run  show what would happen
#
# Every file is linked on its own (no folder links), so programs that write
# next to their config don't write into the repo. Anything already in the way
# is moved to <name>.bak-dotfiles-<date>. Files ending in .in are copied with
# @HOME@ replaced, for programs that don't expand ~.
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
bin=$HOME/.local/bin
stamp=$(date +%Y%m%d-%H%M%S)
deps=0 fonts=0 ada=1 dry=0

for a in "$@"; do
	case $a in
	--deps) deps=1 ;;
	--fonts) fonts=1 ;;
	--no-ada) ada=0 ;;
	--dry-run) dry=1 ;;
	-h | --help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
	*) echo "unknown option: $a" >&2; exit 2 ;;
	esac
done

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
run() { if ((dry)); then echo "    $*"; else "$@"; fi; }

# Move whatever is at $1 out of the way, unless it already is what we want.
clear_target() {
	local t=$1
	[[ -e $t || -L $t ]] || return 0
	run mv "$t" "$t.bak-dotfiles-$stamp"
	echo "    backed up $t"
}

link() {
	local src=$1 dst=$2
	[[ -L $dst && $(readlink "$dst") == "$src" ]] && return 0
	run mkdir -p "$(dirname "$dst")"
	clear_target "$dst"
	run ln -s "$src" "$dst"
	echo "    $dst"
}

render() {
	local src=$1 dst=${2%.in}
	local tmp
	tmp=$(mktemp)
	sed "s|@HOME@|$HOME|g" "$src" >"$tmp"
	if [[ -f $dst && ! -L $dst ]] && cmp -s "$tmp" "$dst"; then rm -f "$tmp"; return 0; fi
	run mkdir -p "$(dirname "$dst")"
	clear_target "$dst"
	if ((dry)); then rm -f "$tmp"; echo "    render $dst"; else mv "$tmp" "$dst"; echo "    $dst (rendered)"; fi
}

install_deps() {
	. /etc/os-release
	case " ${ID:-} ${ID_LIKE:-} " in
	*" arch "*)
		say "Installing packages (pacman)"
		# shellcheck disable=SC2046
		run sudo pacman -S --needed $(grep -v '^#' "$repo/packages/arch.txt")
		if ! command -v mango >/dev/null; then
			if command -v paru >/dev/null; then run paru -S --needed mangowm-git
			elif command -v yay >/dev/null; then run yay -S --needed mangowm-git
			else echo "    MangoWC: install mangowm-git from the AUR"; fi
		fi
		;;
	*" gentoo "*)
		say "Installing packages (emerge)"
		# shellcheck disable=SC2046
		run sudo emerge --ask --noreplace $(grep -v '^#' "$repo/packages/gentoo.txt")
		;;
	*)
		say "Unknown distro (${ID:-?}): install the packages in packages/ by hand"
		;;
	esac
}

install_fonts() {
	local dir=$HOME/.local/share/fonts/nerd-fonts ver=v3.4.0 f tmp
	say "Downloading Nerd Fonts $ver to $dir"
	for f in Meslo GeistMono; do
		[[ -d $dir/$f ]] && { echo "    $f already there"; continue; }
		((dry)) && { echo "    fetch $f"; continue; }
		tmp=$(mktemp -d)
		curl -fL --progress-bar -o "$tmp/$f.tar.xz" \
			"https://github.com/ryanoasis/nerd-fonts/releases/download/$ver/$f.tar.xz"
		mkdir -p "$dir/$f"
		tar -xJf "$tmp/$f.tar.xz" -C "$dir/$f"
		rm -rf "$tmp"
	done
	((dry)) || fc-cache -f "$HOME/.local/share/fonts"
}

build_ada() {
	say "Building ada"
	if [[ ! -f $repo/ada/meson.build ]]; then
		run git -C "$repo" submodule update --init ada
	fi
	if [[ -d $repo/ada/build ]]; then
		run meson setup --reconfigure "$repo/ada/build" "$repo/ada" -Dprefix="$HOME/.local"
	else
		run meson setup "$repo/ada/build" "$repo/ada" -Dprefix="$HOME/.local"
	fi
	run ninja -C "$repo/ada/build" install
}

((deps)) && install_deps
((fonts)) && install_fonts

say "Linking configs into $cfg"
while IFS= read -r -d '' f; do
	rel=${f#"$repo/config/"}
	case $rel in
	*.example) ;;
	*.in) render "$f" "$cfg/$rel" ;;
	*) link "$f" "$cfg/$rel" ;;
	esac
done < <(find "$repo/config" -type f -print0 | sort -z)
link "$repo/ada/data/rofi.rasi" "$cfg/ada/rofi.rasi"

say "Linking scripts into $bin"
for f in "$repo"/bin/*; do link "$f" "$bin/$(basename "$f")"; done

if [[ ! -e $cfg/mango/local.conf ]]; then
	say "Creating $cfg/mango/local.conf (machine-specific: monitors, keyboard)"
	run cp "$repo/config/mango/local.conf.example" "$cfg/mango/local.conf"
fi

((ada)) && build_ada

say "Done"
command -v mango >/dev/null || echo "    mango is not installed yet (--deps, or see README)"
fc-list | grep -q 'MesloLGS Nerd Font' || echo "    MesloLGS Nerd Font missing: ada's icons will be boxes (--fonts)"
command -v cliphist >/dev/null || echo "    cliphist missing: clipboard history (SUPER+Shift+v) won't work"
echo "    Log in on tty1 with fish as your shell and mango starts, or run: mango"
