wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list

apt install -y apt-transport-https
apt update

apt install -y \
	gcc \
	g++ \
	make \
	automake \
	htop \
	tmux \
	git \
	vim \
	awesome \
	xorg \
	acpi \
	lightdm \
	firefox-esr \
	ntfs-3g \
	pulseaudio-utils \
	alsa-utils \
	pulse-audio \
	pulseaudio \
	mpv \
	snapcraft \
	snapd \
	gnome-terminal \
	fonts-firacode \
	dconf-cli \
	code \
	network-manager

wget -qO- https://get.docker.com/ | bash
