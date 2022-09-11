ARG BASE=debian
FROM ${BASE}

COPY . /usr/local/dotfiles
RUN cd /usr/local/dotfiles && ./install.sh

CMD ["/bin/bash"]
