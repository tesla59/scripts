#!/bin/sh
# Server Setup Script

USER="tesla"
THEME="jonathan"

# TODOs
# Create new user, Add Pub keys
# Setup ZSH
# Setup Plugins git sudo zsh-interactive-cd zsh-autosuggestions zsh-syntax-highlighting
# Setup packages

CreateUser() {
    sudo useradd -U -m -d '/home/$USER' -s '/bin/zsh' $USER
    sudo usermod -aG sudo $USER
}

SetupSSH() {
    mkdir -p /home/$USER/.ssh
    touch /home/$USER/.ssh/authorized_keys
    cat "$HOME"/.ssh/authorized_keys >> /home/$USER/.ssh/authorized_keys
}

SetupZsh() {
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install zsh -y
    wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
    sudo -u $USER sh install.sh
    sed -i "s/robbyrussell/$THEME/g" /home/$USER/.zshrc
}

ClonePlugins() {
    # TODO: Add sudo zsh-interactive-cd zsh-syntax-highlighting zsh-autosuggestions to .zshrc
    
    # zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting
    # zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
}

SetupPackages() {
    # Caddy
    sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt update -y
    sudo apt install caddy -y
    
    # Golang
    sudo snap install go --classic
}

# Create User and add to sudoer group
if [ "$(cat /etc/passwd)" =~ $USER ]; then
    # Create a new User
    CreateUser
    SetupSSH
fi

# Setup ZSH
SetupZsh

# Clone all plugins
ClonePlugins

# Setup Packages
SetupPackages

