# Environment {{{
# Personal bin
if [ -d ~/bin ]; then
	PATH="~/bin:$PATH"
fi

if [ -d ~/dotfiles/bin ]; then
	PATH="~/dotfiles/bin:$PATH"
fi

# Prefer vim
command -v vim >/dev/null && {
	export EDITOR=vim
}

command -v nvim >/dev/null && {
	export EDITOR=nvim
}

[ -f ~/bin/nvim ] && export EDITOR="~/bin/nvim"

# Allow **
[ -z "$IS_MAC" ] && shopt -s globstar
# }}}
# Stop if we are not running interactivly {{{
case $- in
    *i*) ;;
      *) return;;
esac
# }}} 
# Platform detection {{{
[ "$(uname)" == "Darwin" ] && IS_MAC=true
# }}}
# History {{{
# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
# }}}
# Prompt {{{
# Set values for LINES and COLUMNS
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
else
	color_prompt=
fi

if [ "$color_prompt" = yes ]; then
	custom_prompt() {
		PS1=""

		# Show running jobs
		if [ $(jobs | wc -l) -gt 0 ]; then
			PS1="$PS1\[\033[1;33m\]$(jobs | wc -l)*\[\033[0m\] "
		fi

		# Show git info in the prompt
		if [ ! -z "$(git rev-parse --git-dir 2>/dev/null)" ]; then
			# Git ahead and behind status 
			local behindBy=""
			case "$(git status | grep -o 'ahead\|behind\|diverged')" in 
				ahead)
					behindBy="+"
					;;
				behind)
					behindBy="-"
					;;
				diverged)
					behindBy="*"
					;;
			esac

			local status="$(git status --porcelain)"
			if [ -z "$status" ]; then
				PS1="$PS1\[\033[1;32m\]"
			else
				PS1="$PS1\[\033[1;33m\]"
			fi
			PS1="$PS1($(git rev-parse --symbolic-full-name -q --abbrev-ref HEAD 2>/dev/null)$behindBy)\[\033[0m\] "
		fi

		# Show only 2 dirs
		local cwd=$(pwd | sed "s/$(echo $HOME | sed 's/\//\\\//g')/~/")
		if [ $(echo $cwd | awk -F/ '{print NF}') -gt 2 ]; then
			cwd="$(echo $cwd | awk -F/ '{print $(NF-1)"/"$NF}')"
		fi
 
		local path_color="\033[01;34m"
		local prompt_char="$"

		# Special root prompt
		if [ $EUID -eq 0 ]; then
			prompt_char="#"
			path_color="\033[0;91m"
		fi

		# Show not ryan/root usernames
		local hostname="\h"
		if [ $EUID -ne 0 ] && [ "$USER" != "ryan" ]; then
			hostname="\u@\h"
		fi

		PS1="$PS1\[\033[00;32m\]$username\h\[\033[00m\]:\[$path_color\]$cwd\[\033[00m\]$prompt_char "
	}

	PROMPT_COMMAND=custom_prompt
else
   	PS1='${debian_chroot:+($debian_chroot)}\h:\w> '
fi
unset color_prompt 
# }}}
# Color cli apps {{{
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
# }}}
# Aliases {{{
# ls aliases
alias ll='ls -alF'
alias la='ls -A'

alias iavpn="/opt/cisco/anyconnect/bin/vpn"
alias sudo="sudo -E"

# Local alias definitions.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
# }}}
# Completion {{{
# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Type just a directory name to cd
[ -z "$IS_MAC" ] && shopt -s autocd

# Enable bash completion for the dotfiles command
. dotfiles bash-completion
# }}}
# Print the banner {{{
if [ -z "$COLUMNS" ] && has_cmd tput; then
	COLUMNS=$(tput cols)
fi

if shopt -q login_shell; then
	# Check if we have sudo
	if command -v sudo >/dev/null; then
		status="$(sudo -nv 2>&1)"

		if [ -z "$status" ]; then
			sudo_status="Sudo allowed"
		elif echo $status | fgrep "may not run sudo" >/dev/null; then
			sudo_status="Sudo denied"
		elif echo $status | fgrep "password is required" >/dev/null; then
			sudo_status="Sudo allowed (password)"
		else
			sudo_status="Sudo unknown"
		fi

		unset status
	fi

	# Get the number of updates available
	if has_cmd apt; then
		updates=$(($(apt list --upgradable 2>/dev/null | wc -l) -1))
		[ "$updates" == "0" ] && updates=""
	fi

	# Check the version of our dotfiles
	if has_cmd git; then
		pushd ~/dotfiles >/dev/null
		sha=$(git log -1 --format=%h)
		dot_status="$(git status --porcelain)"
		[ -z "$dot_status" ] || dot_status="+"
		popd >/dev/null

		dot_version=" $sha$dot_status"
		unset sha dot_status 
	fi

	# List the tmux sessions we have open
	if has_cmd tmux; then
		tmux_sessions=$(tmux list-sessions -F "#S" 2>/dev/null | tr '\n' ',')
		# Strip the tailing ,
		if [ ! -z "$tmux_sessions" ]; then
			tmux_sessions=${tmux_sessions:0:$((${#tmux_sessions} - 1))}
			tmux_sessions="Tmux - $(echo $tmux_sessions | sed 's/,/, /g')"
		fi
	fi

	# Display some information
	source ~/dotfiles/box

	box_lines=("Dotfiles$dot_version")
	[ -z "$sudo_status" ] || box_lines+=("$sudo_status")
	[ -z "$updates" ] || box_lines+=("$updates Updates")
	[ -z "$tmux_sessions" ] || box_lines+=("$tmux_sessions")

	box

	unset box_lines box sudo_status dot_version
fi
# }}}
