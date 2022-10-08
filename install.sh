#!/bin/sh

# Switch to bash on systems that have it
if command -v bash >/dev/null && [ -z "$__SWITCHED_TO_BASH" ]; then
	export __SWITCHED_TO_BASH=1
	exec bash $0 $@
fi

set -e

dotfiles="$(realpath "$(dirname "$0")")"
source $dotfiles/platform

cat $dotfiles/header

R3_SYSTEM_WIDE=yes
if echo "$dotfiles" | grep -E '^/(home|root)' >/dev/null; then
	R3_SYSTEM_WIDE=no
fi

########################################
# Prompts                              #
########################################

prompt() {
	PROMPT_RESULT="$1"
	[ -z "$1" ] && read -p "$2: " PROMPT_RESULT || :
}

prompt_yn() {
	prompt "$1" "$2 [y/N]"

	if echo "$PROMPT_RESULT" | grep -E "^[Yy][Ee]?[Ss]?$" >/dev/null; then
		PROMPT_RESULT=yes
	else
		PROMPT_RESULT=no
	fi
}

prompt_yn "$R3_INSTALL_EXTRA" "Install extra packages (dig, traceroute...)"
R3_INSTALL_EXTRA="$PROMPT_RESULT"
prompt_yn "$R3_INSTALL_DOCKER" "Install docker"
R3_INSTALL_DOCKER="$PROMPT_RESULT"

echo "Install info"
echo "--------------------------------------"
print_platform
echo "R3_SYSTEM_WIDE = $R3_SYSTEM_WIDE"
echo "R3_INSTALL_BASE = $R3_INSTALL_BASE"
echo "R3_INSTALL_EXTRA = $R3_INSTALL_EXTRA"
echo "R3_INSTALL_DOCKER = $R3_INSTALL_DOCKER"
echo

########################################
# Install packages                     #
########################################

BASE_PACKAGES="vim tmux curl git bash"
EXTRA_PACKAGES="traceroute dnsutils tcpdump"

pkg_install $BASE_PACKAGES
[ "$R3_INSTALL_EXTRA" == "yes" ] && pkg_install $EXTRA_PACKAGES

if [ "$R3_INSTALL_DOCKER" == "yes" ]; then
	tmp="$(mktemp)"
	download "https://get.docker.com/" "$tmp"
	bash "$tmp"
	rm "$tmp"
fi

########################################
# Symlink dotfiles                     #
########################################

if [ "$R3_SYSTEM_WIDE" == "yes" ]; then
	for bashrc in /etc/bash.bashrc /etc/bashrc /etc/bash/bashrc; do
		[ -f $bashrc ] && link $dotfiles/bashrc $bashrc
	done
	link $dotfiles/vimrc /etc/vim/vimrc
	link $dotfiles/tmux.conf /etc/tmux.conf
	if ! fgrep "$dotfiles/bin/greeter" /etc/profile >/dev/null; then
		echo -e "# Print system info on login\n$dotfiles/bin/greeter" >>/etc/profile
	fi
else
	mkdir -p ~/.config/git/
	link $dotfiles/gitignore ~/.config/git/ignore
	link $dotfiles/bashrc ~/.bashrc
	link $dotfiles/vimrc ~/.vimrc
	link $dotfiles/tmux.conf ~/.tmux.conf
	if ! fgrep "$dotfiles/bin/greeter" ~/.profile >/dev/null; then
		echo -e "# Print system info on login\n$dotfiles/bin/greeter" >>~/.profile
	fi
fi

########################################
# Install vim plugins                  #
########################################

if has_cmd vim; then
	vim_dir=~/.vim

	[ "$R3_SYSTEM_WIDE" == "yes" ] && vim_dir=/etc/vim

	if [ -f $vim_dir/autoload/plug.vim ]; then
		echo "Installing vim plugins"
		vim +PlugUpgrade +PlugClean +PlugUpdate +qall >/dev/null 2>&1
		echo "Plugins installed"
	else 
		mkdir -p $vim_dir/autoload
		download https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
			$vim_dir/autoload/plug.vim 

		echo "Installing vim plugins"
		vim +PlugInstall +qall >/dev/null 2>&1
		echo "Plugins installed"
	fi
fi
