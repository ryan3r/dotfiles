#!/bin/bash

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

USER_GROUP="${MAIN_USER}"

# Parse the output of the id command to recreate a user from the host
if [ -n "$ID" ]; then
	PUID="$(echo "$ID" | grep -Eo 'uid=\d+' | cut -d '=' -f 2)"
	PGID="$(echo "$ID" | grep -Eo 'gid=\d+' | cut -d '=' -f 2)"
	MAIN_USER="$(echo "$ID" | grep -Eo 'uid=\d+\([^)]+\)' | cut -d '(' -f 2 | cut -d ')' -f 1)"
	USER_GROUP="$(echo "$ID" | grep -Eo 'gid=\d+\([^)]+\)' | cut -d '(' -f 2 | cut -d ')' -f 1)"
fi

# Create the user
groupadd ${USER_GROUP} -g ${PGID}
useradd_opts=""
[ ! -d "/home/${MAIN_USER}" ] && useradd_opts="-m"
useradd $useradd_opts ${MAIN_USER} --comment "${MAIN_USER},,," -s /bin/bash -u ${PUID} -g ${PGID}
echo "${MAIN_USER}	ALL=(ALL:ALL) NOPASSWD:ALL" >/etc/sudoers.d/main_user

# Add the user to the docker group if the socket available
DOCKER_SOCK="/var/run/docker.sock"
if [ -S $DOCKER_SOCK ]; then
	groupdel docker 2>/dev/null
	groupadd docker -g $(stat -c %g $DOCKER_SOCK)
	usermod -aG docker "${MAIN_USER}"
fi

# cd to the user's home directory
if [ "$(pwd)" == "/" ]; then
	cd "/home/${MAIN_USER}"
fi

unset USER_GROUP ID PUID PGID DOCKER_SOCK useradd_opts

# Switch users
if command -v su-exec >/dev/null; then
	exec su-exec "${MAIN_USER}" "$@"
elif command -v gosu >/dev/null; then
	exec gosu "${MAIN_USER}" "$@"
else
	echo "Could not switch users" >&2
	exec "$@"
fi
