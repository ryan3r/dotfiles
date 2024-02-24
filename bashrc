############################################################
# Load machine specific bashrc                             #
############################################################

if [ -f ~/.bashrc.local ]; then
	source ~/.bashrc.local
fi

############################################################
# Help                                                     #
############################################################
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


############################################################
# Environment                                              #
############################################################

# Prefer vim
command -v vim >/dev/null && {
	export EDITOR=vim
	__r3_cli_editor=vim
}

command -v nvim >/dev/null && {
	export EDITOR=nvim
	__r3_cli_editor=nvim
}

[ -z "$R3_MAIN_USER" ] && export R3_MAIN_USER="ryan"

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


############################################################
# System info                                              #
############################################################

__bordered() {
	__border 58 "~" "<" ">"
	$*
	echo
}

__r3_print_versions() {
	local versions=""
	local color="$1"
	shift

	for cmd in "$@"; do
		if command -v $cmd &>/dev/null; then
			versions+="${color}$cmd\e[30m/$($cmd --version | grep -Po '\d+\.\d+(\.\d+)?' | head -1)\e[0m "
		fi
	done

	[ -n "$versions" ] && echo -e "$versions"
}

__r3_print_tool_versions() {
	__r3_print_versions "\e[0;35m" vim nvim git docker
	__r3_print_versions "\e[0;33m" python pip python3 pip3
	__r3_print_versions "\e[0;32m" node nodejs npm yarn
	__r3_print_versions "\e[0;34m" gcc g++ make cmake clang clangd
}

info() {
	echo -e "\n$(__heading "Tools")"
	__r3_print_tool_versions

	local ips="$(ip -o address 2>/dev/null)"
	local macs="$(ip -o link 2>/dev/null)"
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

	[[ $(type -t _r3_extra_info) == function ]] && _r3_extra_info
}


############################################################
# Stop if we are not running interactivly                  #
############################################################

[[ "$-" == *i* ]] || return
 
############################################################
# Color cli apps                                           #
############################################################

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

############################################################
# Aliases                                                  #
############################################################

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

############################################################
# General                                                  #
############################################################

__r3_source_file="$(realpath -- "${BASH_SOURCE[0]}")"

add_section General
mk_alias reload "unset __R3_NOT_NEW_SHELL ; source ${__r3_source_file}" "Reload ${__r3_source_file}"

add_help e "Open a file with your editor"
e() {
	local editor="$(echo $EDITOR | cut -d ' ' -f 1)"

	if [ -w "$1" ]; then
		"$editor" "$1"
	else
		sudo "${__r3_cli_editor:-vim}" "$1"
	fi

	return $?
}


mk_alias eb "e source ${__r3_source_file}"
mk_alias ll 'ls -alF'
mk_alias la 'ls -A'
mk_alias mk 'mkdir -p'

# Python
if command -v python3 >/dev/null; then
	mk_alias py python3
elif command -v python >/dev/null; then
	mk_alias py python
fi


############################################################
# Tmux                                                     #
############################################################

if command -v tmux >/dev/null; then
	add_section Tmux
	mk_alias ta "tmux attach"
	mk_alias tae "tmux attach && exit"
	mk_alias ts "tmux new -s" "New tmux session <session>"
	mk_alias tse "exec tmux new -s" "New tmux session <session> & exit"
fi

############################################################
# Git                                                      #
############################################################

if command -v git >/dev/null; then
	[ -z "$GIT_MAIN_BRANCHES" ] && GIT_MAIN_BRANCHES=("master" "main")

	_fork_point() {
		local commit="$(git rev-parse HEAD)"
		for branch in ${GIT_MAIN_BRANCHES[@]}; do
			if git merge-base $branch $commit 2>/dev/null; then
				echo $branch
				break
			fi
		done
	}

	add_section "Git status/log"
	mk_alias lg 'git log --graph --oneline $(_fork_point | head -1)..' "One line git log"
	mk_alias l1 'git log -1' "Last commit"
	mk_alias gs 'git status'
	mk_alias gd 'git diff'
	mk_alias gdf 'git diff $(_fork_point | head -1)..' "Git diff since fork from \$GIT_MAIN_BRANCHES"
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

	add_help "wto" "Add a worktree (don't branch) <branch_name> [folder_name]"
	wta() {
		git worktree add "${R3_WORKSPACE_ROOT:-..}/${2:-$1}" "$1"
	}

	add_help "wtb" "Add a worktree and branch <branch_name> [folder_name]"
	wtb() {
		git worktree add -b "${R3_WORKSPACE_ROOT:-..}/${2:-$1}" "$1"
	}

	add_section "Miscellaneous git"
	mk_alias groot 'cd "$(git rev-parse --show-toplevel)"' "Cd to git root"
	mk_alias unstage '(groot && git reset HEAD -- .)' "Unstage all changes"
	mk_alias clean '(groot && git clean -Xdff)' "Delete git ignored files (keeps new)"
	mk_alias nuke '(groot && unstage && git clean -xdff -e .vscode && git checkout -f)' "Wipe everything clean"

	add_section "Git remotes and merging"
	mk_alias gf 'git fetch --tags -f --all' "Git fetch all remotes w/ tags"

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
	mk_alias mro 'git merge origin/$(_fork_point | tail -1)' "Git merge origin"
	add_help rbo 'git rebase origin/$(_fork_point | tail -1)' "Git rebase origin"
fi

############################################################
# Docker                                                   #
############################################################

if command -v docker >/dev/null; then
	docker_sudo=""
	if [ ! -w /var/run/docker.sock ]; then
		docker_sudo="sudo "
	fi

	add_section "Docker"
	mk_alias "dp" "${docker_sudo}docker ps"
	mk_alias "di" "${docker_sudo}docker images"
	mk_alias "dr" "${docker_sudo}docker run --rm -it" "Docker run interactive and remove"
	mk_alias "dk" "${docker_sudo}docker kill"
	mk_alias "dcp" "${docker_sudo}docker container prune"
	mk_alias "dsp" "${docker_sudo}docker system prune"
	mk_alias "dup" "${docker_sudo}docker compose up"
	mk_alias "dud" "${docker_sudo}docker compose up -d"
	mk_alias "ddn" "${docker_sudo}docker compose down"
	
	add_help 'dka' "Kill all containers"
	dka() {
		docker kill "$(docker ps -q)"
	}

	unset docker_sudo
fi

############################################################
# VS Code                                                  #
############################################################

if [ "$TERM_PROGRAM" == "vscode" ]; then
	export EDITOR="code --wait"

	add_section "VS Code"
	mk_alias cor "code --reuse-window"
	mk_alias con "code --new-window"
	mk_alias coa "code --add"
fi

unset mk_alias

############################################################
# Completion                                               #
############################################################

shopt -s globstar
shopt -s autocd

############################################################
# History                                                  #
############################################################

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
# Keep my full histpry
HISTSIZE=
HISTFILESIZE=
shopt -s histappend

############################################################
# Prompt                                                   #
############################################################

__r3_prompt_ssh_agent() {
	local color=""

	ssh-add -l &>/dev/null
	local status=$?
	if [ $status -eq 1 ]; then
		color="1;33"
	elif [ $status -gt 1 ]; then
		color="1;31"
	fi

	[ -n "$color" ] && echo "\[\e[${color}m\]!\[\e[0m\] "
}

__r3_prompt_jobs() {
	local jobs_result="$(jobs -l)"
	# Show running jobs
	if [ -n "$jobs_result" ]; then
		echo "\[\033[1;36m\][$(echo "$jobs_result" | awk '{print $4}' | xargs | tr ' ' ',')]\[\033[0m\] "
	fi
}

__r3_prompt_git() {
	if [ -z "$__r3_timeout_set" ] && command -v timeout &>/dev/null && [ "${__r3_shell}" == "bash" ]; then
		# Git commands can be slow on certain remote fs's don't hold up our prompt
		timeout 0.1 bash -c "$(declare -pf __r3_prompt_git); __r3_timeout_set=yes; __r3_prompt_git" || echo "\[\e[31m\][S]\[\e[0m\] "
		return
	fi

	# Show git info in the prompt
	if [ -n "$(git rev-parse --git-dir 2>/dev/null)" ]; then
		# Git ahead and behind status 
		local behindBy=""
		case "$(git status 2>/dev/null | grep -o 'ahead\|behind\|diverged')" in 
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

		local status="$(git status --porcelain 2>/dev/null)"
		local statusColor=""
		if [ -z "$status" ]; then
			statusColor="\[\033[1;32m\]"
		else
			statusColor="\[\033[1;33m\]"
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

		echo "$statusColor($ref$behindBy)\[\033[0m\] "
	fi
}

__r3_prompt_venv() {
	# Show venv name
	[ -z "$VIRTUAL_ENV" ] || echo "\[\033[00;36m\][$(basename "$VIRTUAL_ENV")]\[\033[00m\] "
}

__r3_prompt_host_and_user() {
	local color="0;32"

	local hostname=""
	# Don't show hostname in containers (it doesn't matter
	if [ ! -f /.dockerenv ]; then
		hostname="${R3_MACHINE_NICKNAME:-$HOSTNAME}"
	fi

	local user="${USER}"
	[ -z "$user" ] && user="$(whoami)"

	# Hide the ryan username
	if [ "$user" == "$R3_MAIN_USER" ]; then
		user=""
	fi

	# Special root color
	if [ "$user" == "root" ]; then
		color="0;31"
	fi

	# If user and hostname are specified we want user@hostname
	if [ -n "$user" ] && [ -n "$hostname" ]; then
		user+="@"
	fi

	if [ -n "$hostname" ]; then
		hostname="\[\e[${color}m\]$user$hostname\[\033[00m\] "
	fi

	echo "$hostname"
}

__r3_prompt_path() {
	local repoRoot="$(git rev-parse --show-toplevel 2>/dev/null)"
	if [ -n "$repoRoot" ]; then
		# If we're in a git repo show the top level folder and any subdirectories we're in
		local base="$(dirname "$repoRoot")"
		local path="$(realpath --relative-to="$base" "$(pwd)")"
	else
		local path='\w'
	fi

	echo "\[\e[0;34m\]$path\[\e[0m\] "
}

# Render the prompt using the segements specified in R3_PROMPT_SEGMENTS
__r3_bash_prompt() {
	PS1=""
	for segment in ${R3_PROMPT_SEGMENTS[@]}; do
		PS1+="$($segment)"
	done
}

PROMPT_COMMAND=__r3_bash_prompt

# Default prompt
R3_PROMPT_SEGMENTS=(
	__r3_prompt_jobs
	__r3_prompt_venv
	__r3_prompt_git
	__r3_prompt_host_and_user
	__r3_prompt_path
)


############################################################
# Keybinds                                                 #
############################################################

add_section "Keybinds"
add_help "Alt-Shift-W" "Who/Finger"
bind -x '"\eW":"__bordered who"'
add_help "Alt-Shift-I" "Useful system info (ctrs, git status, jobs, tmux...)"
bind -x '"\eI":"__bordered info"'
add_help "Alt-Shift-R" "Reload bashrc"
bind -x '"\eR":"reload"'

############################################################
# SSH agent                                                #
############################################################

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

############################################################
# Cleanup environment                                      #
############################################################

unset add_help add_section

############################################################
# Print helpful info on login                              #
############################################################

__r3_greeter() {
	local msg="Good "

	local hour=$(date +%H)
	if [ $hour -lt 5 ] || [ $hour -gt 21 ]; then
		msg+="night"
	elif [ $hour -lt 12 ]; then
		msg+="morning"
	elif [ $hour -lt 18 ]; then
		msg+="afternoon"
	else
		msg+="evening"
	fi

	local tmux_count="$(tmux ls 2>/dev/null | wc -l)"
	if [ -n "$tmux_count" ] && [ "$tmux_count" != "0" ]; then
		msg+=", \e[1;36m$tmux_count tmux session\e[0m"
	fi

	ssh-add -l &>/dev/null
	if [ $? -eq 1 ]; then
		msg+=", \e[1;33mNo keys!\e[0m"

		if [ -n "$SSH_AGENT_PID" ]; then
			msg+=" \e[1;35m(L)\e[0m"
		fi
	fi

	local onlineUsers=$(who | cut -d ' ' -f 1 | sort | uniq | wc -l)
	if [ $onlineUsers -gt 1 ]; then
		msg+=", \e[1;32m$onlineUsers users online\e[0m"
	fi

	[[ $(type -t _r3_greeter_hook) == function ]] && msg+="$(_r3_greeter_hook)"

	echo -e "$msg"
}

if [ -z "$__R3_NOT_NEW_SHELL" ]; then
	__r3_greeter
	export __R3_NOT_NEW_SHELL=1
fi

############################################################
# Post bashrc hook (for machine specific customizations)   #
############################################################

[[ $(type -t _r3_post_bashrc) == function ]] && _r3_post_bashrc
unset _r3_post_bashrc

