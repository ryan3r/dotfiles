# syntax=docker/dockerfile:1.4
ARG BASE=debian
FROM ${BASE}

# Install dotfiles and dependencies
ARG MAIN_USER=dev
ENV MAIN_USER=${MAIN_USER}
COPY . /usr/local/dotfiles
RUN --mount=type=cache,id=apt,target=/var/lib/apt \
	--mount=type=cache,id=apk,target=/var/lib/apk \
	cd /usr/local/dotfiles && ./install.sh

# Install container dependencies
RUN --mount=type=cache,id=apt,target=/var/lib/apt \
	--mount=type=cache,id=apk,target=/var/lib/apk \
	 bash -c '. /usr/local/dotfiles/platform && pkg_install sudo passwd gosu'

# Install tini
ARG TINI_VERSION=v0.19.0
RUN . /usr/local/dotfiles/platform && \
	echo ${PLATFORM_ARCH} && \
	download https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-${PLATFORM_ARCH} /tini \
	&& chmod +x /tini
ENTRYPOINT ["/tini", "--", "/usr/local/dotfiles/init.sh"]

CMD ["/bin/bash"]
