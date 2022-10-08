# Load machine specific bashrc {{{
if [ -f ~/.bashrc.local ]; then
	source ~/.bashrc.local
fi
# }}}
# Help {{{
__help=""

__border() {
	echo -ne "\e[1;30m"
	[ -n "$3" ] && echo -ne "$3"
	printf "%0.s${2:--}" $(seq 1 ${1:-60})
	[ -n "$4" ] && echo -ne "$4"
	echo -e "\e[0m"
}

__heading() {
	echo -e "\e[1;36m$1\n$(__border)"
}

add_section() {
	__help+="\n$(__heading "$1")\n"
}

add_help() {
	__help+="$(printf "%-12s \e[1;30m|\e[0m %s" "$1" "$2") \n"
}

help() {
	echo -e "$__help" | less -R
}

# }}}
# Environment {{{
# Prefer vim
command -v vim >/dev/null && {
	export EDITOR=vim
}

command -v nvim >/dev/null && {
	export EDITOR=nvim
}

[ "$TERM_PROGRAM" == "vscode" ] && {
	export EDITOR="code --wait"
}

[ -z "$MAIN_USER" ] && export MAIN_USER="ryan"

path_add() {
	if ! echo $PATH | grep -E "(^|:)$1(:|$)" >/dev/null && [ -d "$1" ]; then
		export PATH="$1:$PATH"
	fi
}

dotfiles=""
for bashrc in ~/.bashrc /etc/bash.bashrc; do
       parent="$(dirname "$(readlink "$bashrc")")"

       if [ "$(basename "$parent")" == "dotfiles" ]; then
               dotfiles="$parent"
               break
       fi
done

path_add "$dotfiles/bin"

unset path_add dotfiles

# }}}
# System info {{{

__bordered() {
	__border 58 "~" "<" ">"
	$*
	echo
}

info() {
	local ips="$(ip -o address)"
	local macs="$(ip -o link)"
	local nics="$(echo "$ips" | grep -E '^[0-9]+: (w|en)[a-z0-9A-Z]+\s+inet ' | awk '{print $2}')"
	if [ -n "$ips" ]; then
		echo -e "\n$(__heading "Network")"
		for nic in $nics; do
			local mac="$(echo "$macs" | fgrep "$nic" | grep -Po "link/ether\s*\K[^ ]+")"
			local addr="$(echo "$ips" | fgrep "$nic" | grep -oP 'inet[^6]\s*\K[^ ]+')"
			printf "%-15s | %15s | %s\n" "$nic" "$addr" "$mac"
		done
	fi

	local running=$(jobs -l 2>/dev/null)
	if [ -n "$running" ]; then
		echo -e "\n$(__heading "Jobs")"
		echo "$running"
	fi

	if [ -n "$(git rev-parse --git-dir 2>/dev/null)" ]; then
		echo -e "\n$(__heading "Git status (max 15 lines)")"
		git -c color.status=always status --short | head -n 15
	fi

	if [ -n "$(tmux ls 2>/dev/null)" ]; then
		echo -e "\n$(__heading "Tmux sessions")"
		tmux ls
	fi

	local ctrs=$(docker ps --format="{{.ID}}\t{{.Names}}\t{{.Image}}" 2>/dev/null)
	if [ -n "$ctrs" ]; then
		echo -e "\n$(__heading "Docker containers")"
		printf "\e[36m%s\e[0m %-20s \e[33m%s\e[0m\n" $ctrs
	fi

	[[ $(type -t _extra_info) == function ]] && _extra_info
}

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
mk_alias() {
	alias "$1"="$2"
	add_help "$1" "${3:-$2}"
}

# Finger (who but better)
if command -v finger >/dev/null; then
	alias who="finger"
fi

# Alias lsd to ls if available
if command -v lsd >/dev/null; then
	alias ls='lsd'
fi

# General {{{
add_section General
mk_alias reload "source ~/.bashrc; echo Reloaded bashrc" "Reload bashrc"
mk_alias e "$(echo $EDITOR | cut -d ' ' -f 1)"
mk_alias eb "e ~/.bashrc"
mk_alias ll 'ls -alF'
mk_alias la 'ls -A'
mk_alias mk 'mkdir -p'

# Python
if command -v python3 >/dev/null; then
	mk_alias py python3
else
	mk_alias py python
fi

# }}}
# Tmux {{{
if command -v tmux >/dev/null; then
	add_section Tmux
	mk_alias ta "tmux attach"
	mk_alias tae "tmux attach && exit"
	mk_alias ts "tmux new -s" "New tmux session <session>"
	mk_alias tse "exec tmux new -s" "New tmux session <session> & exit"
fi
# }}}
# Git {{{
if command -v git >/dev/null; then
	GIT_MAIN_BRANCHES=("master" "main")

	_fork_point() {
		local commit="$(git rev-parse HEAD)"
		for branch in ${GIT_MAIN_BRANCHES[@]}; do
			if git merge-base $branch $commit 2>/dev/null; then
				break
			fi
		done
	}

	_fork_branch() {
		local commit="$(git rev-parse HEAD)"
		for branch in ${GIT_MAIN_BRANCHES[@]}; do
			if git merge-base $branch $commit >/dev/null 2>/dev/null; then
				echo $branch
				break
			fi
		done
	}

	add_section "Git status/log"
	mk_alias lg 'git log --graph --oneline $(_fork_point)..' "One line git log"
	mk_alias l1 'git log -1' "Last commit"
	mk_alias gs 'git status'
	mk_alias gd 'git diff'
	mk_alias gdf 'git diff $(_fork_point)..' "Git diff since fork from \$GIT_MAIN_BRANCHES"
	mk_alias gb 'git branch'

	add_section "Git branches/commits"
	mk_alias co 'git checkout'
	mk_alias cb 'git checkout -b'
	mk_alias br 'git branch -m' "Rename branch <name>"
	mk_alias bd	'git branch -D' "Delete branch (unsafe) <name>"
	mk_alias undo 'git reset --soft HEAD~1' "Undo last commit"
	mk_alias cm 'git commit'
	mk_alias ca 'git commit --amend'

	add_help "ga" "Add the specified files or all of them"
	ga() {
		if [ $# -eq 0 ]; then
			git add .
		else
			git add "$@"
		fi
	}

	add_section "Git worktree"
	mk_alias wtl 'git worktree list'
	mk_alias wtr 'git worktree remove'

	add_help "wta" "Add a worktree (don't branch) <branch_name>"
	wta() {
		git worktree add "../$1" "$1"
	}

	add_help "wtb" "Add a worktree and branch <branch_name>"
	wtb() {
		git worktree add -b "../$1" "$1"
	}

	add_section "Miscellaneous git"
	add_help groot "Cd to git root"
	groot() {
		cd "$(git rev-parse --show-toplevel)"
	}

	mk_alias unstage '(groot && git reset HEAD -- .)' "Unstage all changes"
	mk_alias clean '(groot && git clean -Xdff -e .vscode)' "Git clean keep ignored"
	mk_alias nuke '(groot && unstage && git clean -xdff -e .vscode && git checkout -f)' "Wipe everything clean"

	add_section "Git remotes and merging"
	add_help gf "Git fetch all remotes w/ tags"
	gf() {
		for remote in $(git remote); do
			git fetch --tags -f "$remote" || return $?
		done
	}

	add_help pu "Git push [remote] [branch]"
	pu() {
		if [ -z "$1" ]; then
			git push
			return $?
		fi

		local remote="origin"
		local branch="$1"
		if [ -n "$2" ]; then
			remote="$1"
			branch="$2"
		fi

		git push -u "$remote" "$branch"
	}

	mk_alias pl 'git pull' "Git pull"
	mk_alias mr 'git merge'
	mk_alias rb 'git rebase'
	mk_alias sq 'git merge --squash'

	add_help mro "Git merge origin"
	mro() {
		git merge origin/"$(_fork_branch)"
	}

	add_help rbo "Git rebase origin"
	rbo() {
		git rebase origin/"$(_fork_branch)"
	}
fi
# }}}
# Docker {{{
if command -v docker >/dev/null; then
	add_section "Docker"
	mk_alias "dp" 'docker ps'
	mk_alias "di" 'docker images'
	mk_alias "dr" 'docker run --rm -it' "Docker run interactive and remove"
	mk_alias "dk" 'docker kill'
	mk_alias "dcp" 'docker container prune'
	mk_alias "dsp" 'docker system prune'
	mk_alias "dup" 'docker compose up'
	mk_alias "dud" 'docker compose up -d'
	mk_alias "ddn" 'docker compose down'
	
	add_help 'dka' "Kill all containers"
	dka() {
		docker kill "$(docker ps -q)"
	}
fi
# }}}

unset mk_alias
# }}}
# Completion {{{
shopt -s globstar
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
pretty_custom_prompt() {
	PS1="$R3_PREFIX"

	# Show running jobs
	if [ -n "$jobs_result" ]; then
		PS1="$PS1\[\033[1;36m\]$(echo "$jobs_result" | wc -l)*\[\033[0m\] "
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

		# Try to show the current branch
		local ref="$(git rev-parse --symbolic-full-name -q --abbrev-ref HEAD 2>/dev/null)"
		# if there is no branch look for a tag
		if [ "$ref" == "HEAD" ]; then
			ref="#$(git describe --tags 2>/dev/null)"
		fi
		# If there is not tag show a hash
		if [ "$ref" == "#" ]; then
			ref="$(git rev-parse --short HEAD 2>/dev/null)"
		fi

		PS1="$PS1($ref$behindBy)\[\033[0m\] "
	fi

	# Show venv name
	local venv=""
	[ -z "$VIRTUAL_ENV" ] || venv="\[\033[00;36m\][$(basename $VIRTUAL_ENV)]\[\033[00m\] "

	less_pretty_prompt "$venv$PS1"
}

less_pretty_prompt() {
	local prompt_prefix="$@"

	# Show only 2 dirs
	local cwd=$(pwd | sed "s/$(echo $HOME | sed 's/\//\\\//g')/~/")
	if [ $(echo $cwd | awk -F/ '{print NF}') -gt 2 ]; then
		cwd="$(echo $cwd | awk -F/ '{print $(NF-1)"/"$NF}')"
	fi

	local path_color=""
	[ -f ~/.hostname_color ] && path_color="\e[$(cat ~/.hostname_color)"
	local prompt_char="$"

	# Special root prompt
	if [ $EUID -eq 0 ]; then
		prompt_char="#"
	fi

	local hostname=""
	# Don't show hostname in containers (it doesn't matter
	if [ ! -f /.dockerenv ] && [ -z "$path_color" ]; then
		hostname="$HOSTNAME"
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


	if [ -n "$hostname" ]; then
		hostname="\[\e[00;32m\]$hostname\[\033[00m\]:"
	fi

	path_color="${path_color:-\033[01;34m}"
	echo -ne "$prompt_prefix\[$path_color\]$hostname\[$path_color\]$cwd\[\033[00m\]$prompt_char "
}

custom_prompt() {
	local slow_msg="\[\e[31m\][S]\[\e[0m\] "
	if command -v timeout >/dev/null; then
		# Git commands can be slow on certain remote fs's don't hold up our prompt
		PS1="$(timeout 0.1 bash -c "jobs_result='$(jobs -l)'; $(declare -pf pretty_custom_prompt); $(declare -pf less_pretty_prompt); pretty_custom_prompt" || less_pretty_prompt "$slow_msg")"
	else
		PS1="$(jobs_result="$(jobs -l)" pretty_custom_prompt)"
	fi
}

PROMPT_COMMAND=custom_prompt
unset color_prompt 
# }}}
# Keybinds {{{
add_section "Keybinds"
add_help "Alt-Shift-W" "Who/Finger"
bind -x '"\eW":"__bordered who"'
add_help "Alt-Shift-I" "Useful system info (ctrs, git status, jobs, tmux...)"
bind -x '"\eI":"__bordered info"'
add_help "Alt-Shift-R" "Reload bashrc"
bind -x '"\eR":"reload"'
# }}}
# SSH agent {{{
if [ -z "$SSH_AUTH_SOCK" ]; then
	mkdir -p ~/.ssh
	source ~/.ssh/agent_env >/dev/null 2>&1

	# ssh-add returns 2 if it can't connect to the agent
	ssh-add -l >/dev/null 2>&1
	if [ $? -eq 2 ]; then
		if [ -n "$SSH_AGENT_TIMEOUT" ]; then
			ssh-agent -t $SSH_AGENT_TIMEOUT >~/.ssh/agent_env
		else
			ssh-agent >~/.ssh/agent_env
		fi

		source ~/.ssh/agent_env >/dev/null
	fi
fi
# }}}
# Cleanup environment {{{
unset add_help add_section
# }}}
# Post bashrc hook (for machine specific customizations {{{
[[ $(type -t _post_bashrc) == function ]] && _post_bashrc
unset _post_bashrc
# }}}
