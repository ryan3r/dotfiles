# Environment {{{
# Prefer vim
command -v vim >/dev/null && {
	export EDITOR=vim
}

command -v nvim >/dev/null && {
	export EDITOR=nvim
}

[ -f ~/bin/nvim ] && export EDITOR="~/bin/nvim"

[ -z "$MAIN_USER" ] && export MAIN_USER="ryan"
# }}}
# Stop if we are not running interactivly {{{
[[ "$-" == *i* ]] || return
# }}} 
# Color cli apps {{{
# Busybox doesn't support color options
if [ ! -L "$(command -v ls)" ]; then
	alias ls='ls --color=auto'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
	alias ip='ip -c'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
# }}}
# Aliases {{{
alias reload="source ~/.bashrc; echo Reloaded bashrc"

# Finger (who but better)
if command -v finger >/dev/null; then
	alias who="finger"
fi

# ls aliases
alias ll='ls -alF'
alias la='ls -A'

# Tmux aliases
alias ta="tmux attach"
alias tae="tmux attach && exit"
alias ts="tmux new -s"
alias tse="exec tmux new -s"

# Alias lsd to ls if available
if command -v lsd >/dev/null; then
	alias ls='lsd'
fi

# Git aliases
GIT_MAIN_BRANCHES=("master" "main")

_fork_point() {
	local commit="$(git rev-parse HEAD)"
	for branch in ${GIT_MAIN_BRANCHES[@]}; do
		if git merge-base $branch $commit 2>/dev/null; then
			break
		fi
	done
}

alias co='git checkout'
alias undo='git reset --soft HEAD~1'
alias lg='git log --graph --oneline $(_fork_point)..'
alias l1='git log -1'
alias gs='git status'
alias gd='git diff'
alias gdf='git diff $(_fork_point)..'
alias ga='git add .'
alias wtl='git worktree list'
alias wtr='git worktree remove'
alias cm='git commit'
alias ce='git commit --amend'
alias ca='git commit --all'

wta() {
	git worktree add "../$1" "$1"
}

# Python
if command -v python3 >/dev/null; then
	alias py='python3'
else
	alias py='python'
fi

# }}}
# Completion {{{
shopt -s globstar

# Type just a directory name to cd
shopt -s autocd
# }}}
# History {{{
# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
# Keep my full histpry
HISTSIZE=
HISTFILESIZE=
shopt -s histappend
# }}}
# Prompt {{{
# Set values for LINES and COLUMNS
shopt -s checkwinsize

pretty_custom_prompt() {
	PS1="$R3_PREFIX"

	# Show running jobs
	if [ $(jobs | wc -l) -gt 0 ]; then
		PS1="$PS1\[\033[1;33m\]$(jobs | wc -l)*\[\033[0m\] "
	fi

	# Show git info in the prompt
	if [ -n "$(git rev-parse --git-dir 2>/dev/null)" ]; then
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

	# Show venv name
	local venv=""
	[ -z "$VIRTUAL_ENV" ] || venv="\[\033[00;36m\][$(basename $VIRTUAL_ENV)]\[\033[00m\] "

	less_pretty_prompt "$venv$PS1"
}

less_pretty_prompt() {
	local prompt_prefix="$*"

	# Show only 2 dirs
	local cwd=$(pwd | sed "s/$(echo $HOME | sed 's/\//\\\//g')/~/")
	if [ $(echo $cwd | awk -F/ '{print NF}') -gt 2 ]; then
		cwd="$(echo $cwd | awk -F/ '{print $(NF-1)"/"$NF}')"
	fi

	local path_color="\033[01;35m"
	local prompt_char="$"

	# Special root prompt
	if [ $EUID -eq 0 ]; then
		prompt_char="#"
	fi

	local hostname=""
	# Don't show hostname in containers (it doesn't matter
	if [ ! -f /.dockerenv ]; then
		hostname="$HOSTNAME"
		path_color="\033[01;34m"
	fi

	# Hide the ryan username
	local user="$(whoami)"
	if [ "$user" != "$MAIN_USER" ]; then
		if [ -n "$hostname" ]; then
			hostname="$user@$hostname"
		else
			hostname="$user"
		fi
	fi

	local hostname_color="00;32"
	[ -f ~/.hostname_color ] && hostname_color="$(cat ~/.hostname_color)"

	if [ -n "$hostname" ]; then
		hostname="\[\033[${hostname_color}m\]$hostname\[\033[00m\]:"
	fi

	echo -ne "$prompt_prefix\[$path_color\]$hostname\[$path_color\]$cwd\[\033[00m\]$prompt_char "
}

custom_prompt() {
	local slow_msg="\[\e[31m\][S]\[\e[0m\] "
	if command -v timeout >/dev/null; then
		# Git commands can be slow on certain remote fs's don't hold up our prompt
		PS1="$(timeout 0.1 bash -c "$(declare -pf pretty_custom_prompt); $(declare -pf less_pretty_prompt); pretty_custom_prompt" || less_pretty_prompt "$slow_msg")"
	else
		PS1="$(pretty_custom_prompt)"
	fi
}

PROMPT_COMMAND=custom_prompt
unset color_prompt 
# }}}
# Keybinds {{{
__border() {
	echo -ne "\e[1;30m"
	printf "%0.s-" {1..60}
	echo -e "\e[0m"
}

__bordered() {
	__border
	$*
	__border
}

info() {
	local header_prefix=""

	local ips="$(ip -o a | grep -E '^[0-9]+: (w|en)[a-z0-9A-Z]+\s+inet ' | awk '{print $2": "$4}')"
	if [ -n "$ips" ]; then
		echo -e "$header_prefix\e[1;36m### Network ###\e[0m"
		echo "$ips"
		header_prefix="\n"
	fi

	local running=$(jobs -l 2>/dev/null)
	if [ -n "$running" ]; then
		echo -e "$header_prefix\e[1;36m### Jobs ###\e[0m"
		echo "$running"
		header_prefix="\n"
	fi

	if [ -n "$(git rev-parse --git-dir 2>/dev/null)" ]; then
		echo -e "$header_prefix\e[1;36m### Git status (max 15 lines) ###\e[0m"
		git -c color.status=always status --short | head -n 15
		header_prefix="\n"
	fi

	if [ -n "$(tmux ls 2>/dev/null)" ]; then
		echo -e "$header_prefix\e[1;36m### Tmux sessions ###\e[0m"
		tmux ls
		header_prefix="\n"
	fi

	local ctrs=$(docker ps --format="{{.ID}}\t{{.Names}}\t{{.Image}}" 2>/dev/null)
	if [ -n "$ctrs" ]; then
		echo -e "$header_prefix\e[1;36m### Docker containers ###\e[0m"
		printf "\e[36m%s\e[0m %-20s \e[33m%s\e[0m\n" $ctrs
		header_prefix="\n"
	fi

	[[ $(type -t _extra_info) == function ]] && _extra_info
}

bind -x '"\eW":"__bordered who"'
bind -x '"\eI":"__bordered info"'
bind -x '"\eR":"reload"'
# }}}
