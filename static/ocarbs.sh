#!/bin/sh

# OMEGA's Custom Auto Rice Boostrapping Script based off OCARBS based off LARBS
# by OMEGA, Mariusz Kuchta, Luke Smith and contributors of the FOSS community
# License: GNU GPLv3

### OPTIONS AND VARIABLES ###

dotfilesrepo=""
nixrepo="https://github.com/omega-800/nixos-config"
progsfile="https://raw.githubusercontent.com/omega-800/OCARBS/master/static/progs.csv"
aurhelper="yay"
repobranch="master"
wantkeyd=true
export TERM=ansi

rssurls="https://lukesmith.xyz/rss.xml
https://videos.lukesmith.xyz/feeds/videos.xml?videoChannelId=2 \"~Luke Smith (Videos)\"
https://www.youtube.com/feeds/videos.xml?channel_id=UC2eYFnH61tmytImy1mTYvhA \"~Luke Smith (YouTube)\"
https://lindypress.net/rss
https://notrelated.xyz/rss
https://landchad.net/rss.xml
https://based.cooking/index.xml
https://artixlinux.org/feed.php \"tech\"
https://www.archlinux.org/feeds/news/ \"tech\"
https://github.com/LukeSmithxyz/voidrice/commits/master.atom \"~LARBS dotfiles\""

### FUNCTIONS ###

installpkg() {
	pacman --noconfirm --needed -S "$1" >/dev/null 2>&1
}

error() {
	# Log to stderr and exit with failure.
	printf "%s\n" "$1" >&2
	exit 1
}

welcomemsg() {
	whiptail --title "Welcome!" \
		--msgbox "Welcome to OMEGA's Custom Auto-Rice Bootstrapping Script!\\n\\nThis script will automatically install a fully-featured Linux desktop, which I use as my main machine.\\n\\n-Mariusz" 10 60

	whiptail --title "Important Note!" --yes-button "All ready!" \
		--no-button "Return..." \
		--yesno "Be sure the computer you are using has current pacman updates and refreshed Arch keyrings.\\n\\nIf it does not, the installation of some programs might fail." 8 70
}

getuserandpass() {
	# Prompts user for new username an password.
	name=$(whiptail --inputbox "First, please enter a name for the user account." 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
	while ! echo "$name" | grep -q "^[a-z_][a-z0-9_-]*$"; do
		name=$(whiptail --nocancel --inputbox "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
	pass1=$(whiptail --nocancel --passwordbox "Enter a password for that user." 10 60 3>&1 1>&2 2>&3 3>&1)
	pass2=$(whiptail --nocancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! [ "$pass1" = "$pass2" ]; do
		unset pass2
		pass1=$(whiptail --nocancel --passwordbox "Passwords do not match.\\n\\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
		pass2=$(whiptail --nocancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
}

usercheck() {
	! { id -u "$name" >/dev/null 2>&1; } ||
		whiptail --title "WARNING" --yes-button "CONTINUE" \
			--no-button "No wait..." \
			--yesno "The user \`$name\` already exists on this system. OCARBS can install for a user already existing, but it will OVERWRITE any conflicting settings/dotfiles on the user account.\\n\\nOCARBS will NOT overwrite your user files, documents, videos, etc., so don't worry about that, but only click <CONTINUE> if you don't mind your settings being overwritten.\\n\\nNote also that OCARBS will change $name's password to the one you just gave." 14 70
}

keydsetupask() {
	whiptail --title "Do you want keyd keyboard remapper" --yes-button "Yup" \
		--no-button "Nope, I'm all good" \
		--yesno "It is recommended to enable it as it makes your life easier. To look for what keys are modified see /home/$name/.config/keyd/default" 8 70 && wantkeyd=true
  echo "[ids]

*

[main]

backspace = capslock

capslock = backspace
" > /etc/keyd/default.conf
}

sysconfig() {
  # timezone
  tz=$(whiptail --inputbox "Please enter timezone (eg. Europe/Zurich)" 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
  ln -sf "/usr/share/zoneinfo/${tz:-Europe/Zurich}" /etc/localtime
  # locale
  locale=$(whiptail --inputbox "Please enter locale (eg. C.UTF-8)" 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
  loc="${locale:-en_US.UTF-8}"
  sed -i "s/#$loc/$loc" /etc/locale.gen
  locale-gen
  echo "LANG=$loc" > /etc/locale.conf
  # keyboard layout
  kb=$(whiptail --inputbox "Please enter a kb variant (eg. de_CH-latin1)" 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
  echo "KEYMAP=${kb:-de_CH-latin1}" > /etc/vconsole.conf
  # hostname
	hostname=$(whiptail --inputbox "Please enter hostname" 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
  echo "${hostname:-archie}" > /etc/hostname
}

preinstallmsg() {
	whiptail --title "Let's get this party started!" --yes-button "Let's go!" \
		--no-button "No, nevermind!" \
		--yesno "The rest of the installation will now be totally automated, so you can sit back and relax.\\n\\nIt will take some time, but when done, you can relax even more with your complete system.\\n\\nNow just press <Let's go!> and the system will begin installation!" 13 60 || {
		clear
		exit 1
	}
}

adduserandpass() {
	# Adds user `$name` with password $pass1.
	whiptail --infobox "Adding user \"$name\"..." 7 50
	useradd -m -g wheel -s /bin/zsh "$name" >/dev/null 2>&1 ||
		usermod -a -G wheel "$name" && mkdir -p /home/"$name" && chown "$name":wheel /home/"$name"
  usermod -aG "$name" kvm,networkmanagerlibvirt,docker,libvirtd,audio,storage,video,nix-users,power,tty
	export repodir="/home/$name/.local/src"
	mkdir -p "$repodir"
	chown -R "$name":wheel "$(dirname "$repodir")"
	echo "$name:$pass1" | chpasswd
	unset pass1 pass2

  sudo -u "$name" mkdir -p "/home/$name/.cache/zsh/"
  sudo -u "$name" mkdir -p "/home/$name/.config/mpd/playlists/"
  sudo -u "$name" mkdir -p "/home/$name/documents/img/screenshots"
  sudo -u "$name" mkdir -p "/home/$name/documents/vid/screenrecordings"
  sudo -u "$name" mkdir -p "/home/$name/workspace/personal"
  sudo -u "$name" mkdir -p "/home/$name/workspace/work"
  sudo -u "$name" mkdir -p "/home/$name/.local/share/gnupg"
  chmod 0600 "/home/$name/.local/share/gnupg" # since we change $GNUPGHOME to this path we need to have this folder created or else we encounter errors when getting packages from aur 
}

refreshkeys() {
	case "$(readlink -f /sbin/init)" in
	*systemd*)
		whiptail --infobox "Refreshing Arch Keyring..." 7 40
		pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
		;;
	*)
		whiptail --infobox "Enabling Arch Repositories for more a more extensive software collection..." 7 40
		if ! grep -q "^\[universe\]" /etc/pacman.conf; then
			echo "[universe]
Server = https://universe.artixlinux.org/\$arch
Server = https://mirror1.artixlinux.org/universe/\$arch
Server = https://mirror.pascalpuffke.de/artix-universe/\$arch
Server = https://artixlinux.qontinuum.space/artixlinux/universe/os/\$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/\$arch
Server = https://ftp.crifo.org/artix-universe/" >>/etc/pacman.conf
			pacman -Sy --noconfirm >/dev/null 2>&1
		fi
		pacman --noconfirm --needed -S \
			artix-keyring artix-archlinux-support >/dev/null 2>&1
		for repo in extra community; do
			grep -q "^\[$repo\]" /etc/pacman.conf ||
				echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" >>/etc/pacman.conf
		done
		pacman -Sy >/dev/null 2>&1
		pacman-key --populate archlinux >/dev/null 2>&1
		;;
	esac
}

enableservice() {
    case "$(readlink -f /sbin/init)" in
      *systemd*) 
        if [ "$2" = U ]; then
            systemctl --user -M $name@ enable "$1"
        else
            systemctl enable "$1"
        fi
        ;;
      *runit*)
        service="/etc/runit/sv/$servicesdir/$1"
        [ -d "$service" ] && return 1
        mkdir $service
        echo '#!/bin/sh\nexec $1' > "$service/run"
        chmod u+x "$service/run"
        ln -s /etc/runit/sv/$1 /run/runit/service ;;
      *dinit*)
        printf "type            = process\ncommand         = /usr/bin/$1" > /etc/dinit.d/$1
        dinitctl enable "$1"
        dinitctl start "$1"
        ;;
      *)
        echo "No compatible init system detected. Feel free to make a pull request"
        ;;
    esac
}

nixinstall() {
  [ -e /etc/bash.bashrc.backup-before-nix ] && rm /etc/bash.bashrc.backup-before-nix
  whiptail --title "OCARBS Installation" \
    --infobox "Installing NIX which is required to install and configure other programs." 8 70
  sudo -iu $name sh <(curl -L https://nixos.org/nix/install) --daemon || error "Failed to install NIX"

  whiptail --title "OCARBS Installation" \
    --infobox "Installing NIX home-manager which is required to install and configure other programs." 8 70
  sudo -iu $name nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager || error "Failed to add home-manager repo"
  sudo -iu $name nix-channel --update || error "Failed to update nix-channel"
  sudo -iu $name nix-shell '<home-manager>' -A install || error "Failed to install home-manager"

  whiptail --title "OCARBS Installation" \
    --infobox "Synchronizing system time to ensure successful and secure installation of software..." 8 70
  ntpd -q -g >/dev/null 2>&1

  $nixcfgpath="/home/$name/workspace/nixos-config"
  $hostcfg="$nixcfgpath/hosts/$hostname"
  sudo --user $name git clone $nixrepo $nixcfgpath
  sudo --user $name cp -r $nixcfgpath/hosts/generic-template $hostcfg
  sed -i "s/setnewhostname/$hostname/" $hostcfg/config.nix
  curpath="$(pwd)"
  cd $nixcfgpath 
  sudo --user $name git add .
  cd "$curpath"
  sudo -iu $name home-manager switch --flake "$nixcfgpath#$hostname" --extra-experimental-features nix-command --extra-experimental-features flakes
}

manualinstall() {
	# Installs $1 manually. Used for AUR helper as well as
	# custom user programs
	# Should be run after repodir is created and var is set.
	if [ -z "$2" ]; then
		reponame=$1
		reposource="https://aur.archlinux.org/$reponame.git"
                pacman -Qq "$reponame" && return 0 # only the aur helper shouldn't be recompiled
	else
		reponame=$(echo $1 | grep -oE '[^/]+$' | cut -d'.' -f1)
		reposource=$1
	fi
	whiptail --infobox "Installing \"$1\" manually." 7 50
	sudo -u "$name" mkdir -p "$repodir/$reponame"
	sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
		--no-tags -q "$reposource" "$repodir/$reponame" ||
		{
			cd "$repodir/$reponame" || return 1
			sudo -u "$name" git pull --force origin master
		}
	cd "$repodir/$reponame" || return 1
	sudo -u "$name" makepkg -sif --noconfirm >/dev/null 2>&1 || return 1
}

maininstall() {
	# Installs all needed programs from main repo.
	whiptail --title "OCARBS Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2" 9 70
	installpkg "$1"
}

gitmakeinstall() {
	progname="${1##*/}"
	progname="${progname%.git}"
	dir="$repodir/$progname"
	whiptail --title "OCARBS Installation" \
		--infobox "Installing \`$progname\` ($n of $total) via \`git\` and \`make\`. $(basename "$1") $2" 8 70
	sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
		--no-tags -q "$1" "$dir" ||
		{
			cd "$dir" || return 1
			sudo -u "$name" git pull --force origin master
		}
	cd "$dir" || exit 1
	make >/dev/null 2>&1
	make install >/dev/null 2>&1
	cd /tmp || return 1
}

aurinstall() {
	whiptail --title "OCARBS Installation" \
		--infobox "Installing \`$1\` ($n of $total) from the AUR. $1 $2" 9 70
	echo "$aurinstalled" | grep -q "^$1$" && return 1
	sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1
}

pipinstall() {
	whiptail --title "OCARBS Installation" \
		--infobox "Installing the Python package \`$1\` ($n of $total). $1 $2" 9 70
	[ -x "$(command -v "pip")" ] || installpkg python-pip >/dev/null 2>&1
	yes | pip install "$1"
}

installationloop() {
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) ||
		curl -Ls "$progsfile" | sed '/^#/d' >/tmp/progs.csv
	total=$(wc -l </tmp/progs.csv)
	aurinstalled=$(pacman -Qqm)
	while IFS=, read -r tag service program comment; do
		n=$((n + 1))
		echo "$comment" | grep -q "^\".*\"$" &&
			comment="$(echo "$comment" | sed -E "s/(^\"|\"$)//g")"
    [ -n "$service" ] && enableservice "$program" "$service"
		case "$tag" in
      "A") aurinstall "$program" "$comment" ;;
      "G") gitmakeinstall "$program" "$comment" ;;
      "P") pipinstall "$program" "$comment" ;;
      "S") manualinstall "$program" "$comment" ;;
      "X") : ;;
      *) maininstall "$program" "$comment" ;;
		esac
	done </tmp/progs.csv
}

putgitrepo() {
	# Downloads a gitrepo $1 and places the files in $2 only overwriting conflicts
	whiptail --infobox "Downloading and installing config files..." 7 60
	[ -z "$3" ] && branch="master" || branch="$repobranch"
	dir=$(mktemp -d)
	[ ! -d "$2" ] && mkdir -p "$2"
	chown "$name":wheel "$dir" "$2"
	sudo -u "$name" git -C "$repodir" clone --depth 1 \
		--single-branch --no-tags -q --recursive -b "$branch" \
		--recurse-submodules "$1" "$dir"
	sudo -u "$name" cp -rfT "$dir" "$2"
}

finalize() {
	whiptail --title "All done!" \
		--msgbox "Congrats! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place.\\n\\nTo run the new graphical environment, log out and log back in as your new user, then run the command \"startw\" to start the graphical environment (it will start automatically in tty1).\\n\\n.t Luke" 13 80
}

### THE ACTUAL SCRIPT ###

### This is how everything happens in an intuitive format and order.

# Check if user is root on Arch distro. Install whiptail.
pacman --noconfirm --needed -Sy libnewt ||
	error "Are you sure you're running this as the root user, are on an Arch-based distribution and have an internet connection?"

# Welcome user and pick dotfiles.
welcomemsg || error "User exited."

# Get and verify username and password.
getuserandpass || error "User exited."

# Give warning if user already exists.
usercheck || error "User exited."

keydsetupask

# Last chance for user to back out before install.
preinstallmsg || error "User exited."

### The rest of the script requires no user input.

sysconfig || error "User exited."

# Refresh Arch keyrings.
refreshkeys || error "Error automatically refreshing Arch keyring. Consider doing so manually."

adduserandpass || error "Error adding username and/or password."

[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case

# Allow user to run sudo without password. Since AUR programs must be installed
# in a fakeroot environment, this is required for all builds with AUR.
trap 'rm -f /etc/sudoers.d/marbs-temp' HUP INT QUIT TERM PWR EXIT
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/marbs-temp

# Make pacman colorful, concurrent downloads and Pacman eye-candy.
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -Ei "s/^#(ParallelDownloads).*/\1 = 5/;/^#Color$/s/#//" /etc/pacman.conf

# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf
for x in curl ca-certificates base-devel git ntp zsh; do
	whiptail --title "OCARBS Installation" \
		--infobox "Installing \`$x\` which is required to install and configure other programs." 8 70
	installpkg "$x"
done

nixinstall

manualinstall $aurhelper || error "Failed to install AUR helper."

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required. Be sure to run this only after
# the user has been created and has priviledges to run sudo without a password
# and all build dependencies are installed.
installationloop

# Install the dotfiles in the user's home directory, but remove .git dir and
# other unnecessary files.
[ -n "$dotfilesrepo" ] && putgitrepo "$dotfilesrepo" "/home/$name" "$repobranch"
echo "$rssurls" > "/home/$name/.config/newsboat/urls"
rm -rf "/home/$name/.git/" "/home/$name/README.md" "/home/$name/LICENSE" "/home/$name/FUNDING.yml"

# Most important command! Get rid of the beep!
rmmod pcspkr
echo "blacklist pcspkr" >/etc/modprobe.d/nobeep.conf

# Make zsh the default shell for the user and set up folders which the system would usually expect.
chsh -s /bin/zsh "$name" >/dev/null 2>&1

echo "source /home/$name/.config/zsh/.zshrc" > /root/.zshrc
echo 'PS1="%B%{$fg[red]%}[%{$fg[red]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[yellow]%}%~%{$fg[red]%}]%{$reset_color%}#%b "' >> /root/.zshrc

# dbus UUID must be generated for Artix runit.
dbus-uuidgen >/var/lib/dbus/machine-id

# Use system notifications for Brave on Artix
echo "export \$(dbus-launch)" >/etc/profile.d/dbus.sh

# All this below to get Librewolf installed with add-ons and non-bad settings.
whiptail --infobox "Setting browser privacy settings and add-ons..." 7 60

browserdir="/home/$name/.librewolf"
profilesini="$browserdir/profiles.ini"

# Start librewolf headless so it generates a profile. Then get that profile in a variable.
sudo -u "$name" librewolf --headless >/dev/null 2>&1 &
sleep 2
profile="$(sed -n "/Default=.*.default-\(default\|release\)/ s/.*=//p" "$profilesini")"
pdir="$browserdir/$profile"

[ -d "$pdir" ] && installffaddons

# Kill the now unnecessary librewolf instance.
pkill -u "$name" librewolf

[ "$wantkeyd" = true ] && enablekeyd

# Allow wheel users to sudo with password and allow several system commands
# (like `shutdown` to run without password).
echo "%wheel ALL=(ALL:ALL) ALL" >/etc/sudoers.d/00-ocarbs-wheel-can-sudo
echo "%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/pacman -Syyuw --noconfirm,/usr/bin/pacman -S -u -y --config /etc/pacman.conf --,/usr/bin/pacman -S -y -u --config /etc/pacman.conf --" >/etc/sudoers.d/01-ocarbs-cmds-without-password
echo "Defaults editor=/usr/bin/nvim" >/etc/sudoers.d/02-ocarbs-visudo-editor
mkdir -p /etc/sysctl.d
echo "kernel.dmesg_restrict = 0" > /etc/sysctl.d/dmesg.conf
echo "    
XDG_CACHE_HOME=$HOME/.cache
XDG_CONFIG_HOME=$HOME/.config
XDG_DATA_HOME=$HOME/.local/share
XDG_STATE_HOME=$HOME/.local/state
XDG_BIN_HOME=$HOME/.local/bin
EDITOR=nvim
MOZ_ENABLE_WAYLAND=1
" >> /etc/profile
# harden the system a bit
[ -e hardening.sh ] || curl -LO https://raw.githubusercontent.com/omega-800/OCARBS/main/static/hardening.sh
[ -x hardening.sh ] || chmod +x hardening.sh
./hardening.sh $name
# TODO: swhkd

# Last message! Install complete!
finalize
