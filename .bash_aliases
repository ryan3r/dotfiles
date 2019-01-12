alias iavpn="/opt/cisco/anyconnect/bin/vpn"
alias dkrun='docker run --rm -v "$(lw $(pwd)):/mnt" -it'
alias update-dotfiles='~/dotfiles/bin/update-dotfiles && source ~/dotfiles/bin/reload-dotfiles'

if $IS_WSL; then
	# Path translations
	lw() {
		local path="$1"
		if [ -z "$path" ]; then
			path="$(pwd)"
		fi

		echo "$path" | sed 's/\//\\/g' | sed -r 's/^\\mnt\\([A-Za-z])/\1:/'
	}

	wl() {
		echo "$1" | sed -r 's/([A-Za-z]):/\/mnt\/\1/g' | sed 's/\\/\//g'
	}
fi
