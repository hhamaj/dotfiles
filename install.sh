#!/usr/bin/env bash
# Links these dotfiles into $HOME and builds ada.
#
#   ./install.sh            link configs + scripts, build and install ada
#   ./install.sh --deps     also install packages (Arch or Gentoo); asks which
#                           groups, or which packages in a group, to install
#   ./install.sh --groups=build,session
#                           install those package groups without asking
#                           (all = every group; list them with --list-groups)
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
deps=0 fonts=0 ada=1 dry=0 groups=

for a in "$@"; do
	case $a in
	--deps) deps=1 ;;
	--groups=*) deps=1 groups=${a#--groups=} ;;
	--list-groups) list_groups=1 ;;
	--fonts) fonts=1 ;;
	--no-ada) ada=0 ;;
	--dry-run) dry=1 ;;
	-h | --help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

distro() {
	. /etc/os-release
	case " ${ID:-} ${ID_LIKE:-} " in
	*" arch "*) echo arch ;;
	*" gentoo "*) echo gentoo ;;
	*) echo "${ID:-unknown}" ;;
	esac
}

# Reads packages/<distro>.txt into: group_names (in order), group_desc[name],
# group_pkgs[name] (space separated).
declare -a group_names=()
declare -A group_desc=() group_pkgs=()
load_groups() {
	local line g=
	group_names=() group_desc=() group_pkgs=()
	while IFS= read -r line; do
		line=${line%%#*}
		[[ $line =~ ^[[:space:]]*$ ]] && continue
		if [[ $line =~ ^\[([a-z0-9_-]+)\][[:space:]]*(.*)$ ]]; then
			g=${BASH_REMATCH[1]}
			group_names+=("$g")
			group_desc[$g]=${BASH_REMATCH[2]}
			group_pkgs[$g]=
		elif [[ -n $g ]]; then
			group_pkgs[$g]+=" $line"
		fi
	done <"$1"
}

installed() {
	local p=${1#aur:}
	case $os in
	arch) pacman -Q "$p" &>/dev/null ;;
	gentoo) compgen -G "/var/db/pkg/$p-[0-9]*" >/dev/null ;;
	esac
}

ask() { # ask PROMPT DEFAULT -> reply in $REPLY
	read -r -p "$1" REPLY || REPLY=
	REPLY=${REPLY:-$2}
}

# Fills $selected with the packages to install.
choose_packages() {
	local g p n
	selected=()
	if [[ -n $groups ]]; then
		[[ $groups == all ]] && groups=$(IFS=,; echo "${group_names[*]}")
		IFS=, read -ra want <<<"$groups"
		for g in "${want[@]}"; do
			[[ -v group_pkgs[$g] ]] || { echo "unknown group: $g (have: ${group_names[*]})" >&2; exit 2; }
			# shellcheck disable=SC2206
			selected+=(${group_pkgs[$g]})
		done
		return
	fi
	if [[ ! -t 0 ]]; then
		for g in "${group_names[@]}"; do selected+=(${group_pkgs[$g]}); done
		return
	fi
	echo "    y = whole group, n = skip, p = pick packages one by one"
	for g in "${group_names[@]}"; do
		# shellcheck disable=SC2206
		local pkgs=(${group_pkgs[$g]})
		n=0
		for p in "${pkgs[@]}"; do installed "$p" && n=$((n + 1)); done
		ask "    [$g] ${group_desc[$g]} (${#pkgs[@]} packages, $n installed) [Y/n/p] " y
		case ${REPLY,,} in
		n*) ;;
		p*)
			for p in "${pkgs[@]}"; do
				if installed "$p"; then
					ask "        $p (installed) [y/N] " n
				else
					ask "        $p [Y/n] " y
				fi
				[[ ${REPLY,,} == y* ]] && selected+=("$p")
			done
			;;
		*) selected+=("${pkgs[@]}") ;;
		esac
	done
}

install_deps() {
	local list=$repo/packages/$os.txt p
	[[ -f $list ]] || { say "No package list for $os: install the packages in packages/ by hand"; return; }
	load_groups "$list"
	say "Choosing packages ($os)"
	choose_packages
	((${#selected[@]})) || { echo "    nothing selected"; return; }

	local repo_pkgs=() aur_pkgs=()
	for p in "${selected[@]}"; do
		case $p in aur:*) aur_pkgs+=("${p#aur:}") ;; *) repo_pkgs+=("$p") ;; esac
	done
	say "Installing ${#selected[@]} packages"
	case $os in
	arch)
		((${#repo_pkgs[@]})) && run sudo pacman -S --needed "${repo_pkgs[@]}"
		if ((${#aur_pkgs[@]})); then
			if command -v paru >/dev/null; then run paru -S --needed "${aur_pkgs[@]}"
			elif command -v yay >/dev/null; then run yay -S --needed "${aur_pkgs[@]}"
			else echo "    no AUR helper: install ${aur_pkgs[*]} from the AUR by hand"; fi
		fi
		;;
	gentoo) run sudo emerge --ask --noreplace "${repo_pkgs[@]}" ;;
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

# Sets $missing to the tools/libraries ada needs that aren't there.
have_build_deps() {
	local t
	missing=()
	for t in meson ninja pkg-config; do command -v "$t" >/dev/null || missing+=("$t"); done
	if command -v pkg-config >/dev/null; then
		for t in wayland-client wayland-protocols wayland-scanner cairo pangocairo json-c libpulse gdk-pixbuf-2.0; do
			pkg-config --exists "$t" || missing+=("$t")
		done
		pkg-config --exists libelogind || pkg-config --exists libsystemd || missing+=("libelogind/libsystemd")
	fi
	((${#missing[@]} == 0))
}

build_ada() {
	say "Building ada"
	if [[ ! -f $repo/ada/meson.build ]]; then
		run git -C "$repo" submodule update --init ada
	fi

	# Build tools and libraries come from the "build" package group.
	if ! have_build_deps; then
		echo "    ada's build dependencies are missing: ${missing[*]}"
		REPLY=n
		if [[ -f $repo/packages/$os.txt && -t 0 ]] && ! ((dry)); then
			ask "    Install the build package group now? [Y/n] " y
		fi
		if [[ ${REPLY,,} == y* ]]; then
			groups=build
			install_deps
			hash -r
			have_build_deps || { echo "    still missing: ${missing[*]}" >&2; return 1; }
		else
			echo "    skipped: run ./install.sh --groups=build to build ada later"
			return 0
		fi
	fi

	if [[ -d $repo/ada/build ]]; then
		run meson setup --reconfigure "$repo/ada/build" "$repo/ada" -Dprefix="$HOME/.local"
	else
		run meson setup "$repo/ada/build" "$repo/ada" -Dprefix="$HOME/.local"
	fi
	run ninja -C "$repo/ada/build" install
}

os=$(distro)
if [[ -n ${list_groups:-} ]]; then
	[[ -f $repo/packages/$os.txt ]] || { echo "no package list for $os" >&2; exit 1; }
	load_groups "$repo/packages/$os.txt"
	for g in "${group_names[@]}"; do
		printf '%-10s %s\n' "$g" "${group_desc[$g]}"
		printf '           %s\n' "${group_pkgs[$g]# }"
	done
	exit 0
fi

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
