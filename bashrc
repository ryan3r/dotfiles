# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Start tmux for ssh connections
# shopt -q login_shell && [ ! -z "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && {
# 	if tmux ls >/dev/null 2>&1; then
# 		exec tmux attach
# 	else
# 		exec tmux new
# 	fi
# }

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

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

		# Check if our dotfiles are behind the remote
		pushd ~/dotfiles >/dev/null
		local behindBy="$(git rev-list --left-right --count master...origin/master 2>&1 | awk '{print $2}')"
		popd >/dev/null

		if [ "$behindBy" != "0" ]; then
			PS1="\[\033[1;31m\]${PS1}U\[\033[0m\] "
		fi

		# Show running jobs
		if [ $(jobs | wc -l) -gt 0 ]; then
			PS1="$PS1\[\033[1;33m\]$(jobs | wc -l)*\[\033[0m\] "
		fi

		# Show git info in the prompt
		if [ ! -z "$(git rev-parse --git-dir 2>/dev/null)" ]; then
			local status="$(git status --porcelain)"
			if [ -z "$status" ]; then
				PS1="$PS1\[\033[1;32m\]"
			else
				PS1="$PS1\[\033[1;33m\]"
			fi
			PS1="$PS1($(git rev-parse --symbolic-full-name -q --abbrev-ref HEAD 2>/dev/null))\[\033[0m\] "
		fi

		# Show only 2 dirs
		local cwd="$(pwd | sed "s/$(echo $HOME | sed 's/\//\\\//g')/~/")"
		if [ $(echo $cwd | awk -F/ '{print NF}') -gt 3 ]; then
			cwd="$(echo $cwd | awk -F/ '{print $(NF-1)"/"$NF}')"
		fi

		PS1="$PS1${debian_chroot:+($debian_chroot)}\[\033[00;32m\]\h\[\033[00m\]:\[\033[01;34m\]$cwd\[\033[00m\]$ "
	}

	fancy_prompt() {
		PS1=""
		local sep="$(echo -e "\ue0b0")"
		local prebranch=""

		# Show running jobs
		if [ $(jobs | wc -l) -gt 0 ]; then
			PS1="\[\033[0;43m\] $(echo -e "\u2699")"
			prebranch="\[\033[033m\]$sep"
		fi

		# Show git info in the prompt
		if [ ! -z "$(git rev-parse --git-dir 2>/dev/null)" ]; then
			# Git ahead and behind status 
			local behindBy="$(git diff --cached --name-only | wc -l)"

			if [ "$behindBy" == "0" ]; then
				case "$(git status | grep -o 'ahead\|behind\|diverged')" in 
					ahead)
						behindBy="+"
						;;
					behind)
						behindBy="-"
						;;
					diverged)
						behindBy="~"
						;;
					*)
						behindBy=""
						;;
				esac
			else
				behindBy=" $(echo -e "\u00b1")$behindBy"
			fi
			
			local status="$(git status --porcelain)"
			local foreground=
			if [ -z "$status" ]; then
				PS1="$PS1\[\033[42m\]$prebranch\[\033[0;37m\]\[\033[1;42m\]"
				foreground="\[\033[0;32m\]"
			else
				PS1="$PS1\[\033[103m\]$prebranch\[\033[0;103m\]\[\033[30m\]"
				foreground="\[\033[0;93m\]"
			fi
			local branch="$(git rev-parse --symbolic-full-name -q --abbrev-ref HEAD 2>/dev/null)"
			PS1="$PS1 $(echo -e "\ue0a0")$branch$behindBy $foreground\[\033[104m\]$sep"
		else
			PS1="$PS1\[\033[48;5;237m\]$prebranch\[\033[37m\]\[\033[1;48;5;237m\] \h \[\033[38;5;237m\]\[\033[104m\]$sep"
		fi

		# Show only 2 dirs
		local cwd="$(pwd | sed "s/$(echo $HOME | sed 's/\//\\\//g')/~/"| awk -F/ '{print $NF}')"
	
		PS1="$PS1\[\033[1;39m\] $cwd \[\033[00m\]\[\033[94m\]$sep\[\033[00m\] "
	}

	prompt_picker() {
		# Set the prompt title
		local cwd="$(pwd | sed "s/$(echo $HOME | sed 's/\//\\\//g')/~/")"
		if [ $(echo $cwd | awk -F/ '{print NF}') -gt 3 ]; then
			cwd="$(echo $cwd | awk -F/ '{print $(NF-1)"/"$NF}')"
		fi

		echo -en "\033]0;$(whoami)@$(hostname): $cwd\a"

		if [ -z "$LC_R3R_FANCY" ]; then
			custom_prompt
		else
			fancy_prompt
		fi
	}

	PROMPT_COMMAND=prompt_picker
else
   	PS1='${debian_chroot:+($debian_chroot)}\h:\w> '
fi
unset color_prompt 


# If this is an xterm set the title to host
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\h\a\]$PS1"
    ;;
*)
    ;;
esac

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

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if [ -f ~/.bash_aliases.local ]; then
	. ~/.bash_aliases.local
fi

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

# Detect wsl
grep -q Microsoft /proc/version && IS_WSL=1

# Make sure the ssh-agent is running and configured
start_ssh_agent() {
	ssh-agent > ~/.ssh-agent-env
	sed -i 's/echo Agent pid [0-9]*;//' ~/.ssh-agent-env
	source ~/.ssh-agent-env

	if [ "$(ssh-add -l 2>/dev/null)" == "The agent has no identities." ]; then
		ssh-add
	fi
}

[ -f ~/.ssh/id_rsa ] && {
	if [ ! -f ~/.ssh-agent-env ]; then
		start_ssh_agent
	fi

	source ~/.ssh-agent-env

	if ! ssh-add -l >/dev/null 2>/dev/null; then
		start_ssh_agent
		source ~/.ssh-agent-env
	fi
}

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

# Connect external docker engine to wsl docker client
if [ ! -z "$IS_WSL" ] && [ ! -S /var/run/docker.sock ]; then
	(sudo bash -c 'socat UNIX-LISTEN:/var/run/docker.sock,fork,group=docker,umask=007 EXEC:"npiperelay.exe -ep -s //./pipe/docker_engine",nofork >/dev/null 2>&1' &)
fi

shopt -s autocd

# Fetch changes in the dotfiles if we have an ssh key
#pushd ~/dotfiles >/dev/null
#if [ "$(ssh-add -l 2>/dev/null)" != "The agent has no identities." ] || [ -z "$(git remote get-url origin | fgrep ssh)" ]; then
#	(git fetch -a >/dev/null 2>&1 &)
#fi
#popd >/dev/null

if [ ! -z "LC_R3R_FANCY" ]; then
	command -v lsd >/dev/null && alias ls="lsd"
fi
