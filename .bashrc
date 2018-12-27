# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

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

		# Show running jobs
		if [ $(jobs | wc -l) -gt 0 ]; then
			PS1="$PS1\[\033[1;33m\]$(jobs -r | wc -l)/$(jobs | wc -l)\[\033[0m\] "
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

		PS1="$PS1${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\h\[\033[00m\]:\[\033[01;34m\]$cwd\[\033[00m\]> "
	}

	PROMPT_COMMAND=custom_prompt
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

# Make sure gpg knows what to use as its tty
export GPG_TTY=$(tty)

# Setup the gpg agent
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
if [ ! -S $SSH_AUTH_SOCK ]; then
	eval $(gpg-agent --daemon)
fi

# Personal bin
if [ -d ~/bin ]; then
	PATH="~/bin:$PATH"
fi

# Prefer vim
command -v vi >/dev/null && {
	export EDITOR=vi
}

command -v vim >/dev/null && {
	export EDITOR=vim
}

command -v vi >/dev/null && (command -v vim >/dev/null || {
	alias vim=vi
})
