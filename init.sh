#!/bin/bash

#### super setup to avoid timeouts
super() {
    echo $pass | sudo -S -p '' $@
}

while [ -z $supered ]
do
    echo -n 'Enter user password : '
    stty -echo
    read pass
    stty echo
    echo ''
    if super true 2>/dev/null; then
        supered=true
    else
        echo -n 'Wrong password. '
    fi
done

super dpkg --configure -a || exit
super apt update && super apt upgrade -y || exit

#? quality of life stuff
super apt install -y zsh neovim fzf pip python-is-python3 || exit
cd ~
git clone https://github.com/guillaumeboehm/linux_new_install || exit
cd linux_new_install
git checkout wm

#zsh
# sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# cd ~/.oh-my-zsh
# while read plug; do
#     list=($plug)
#     url=${list[0]}
#     path=${list[1]}
#     echo "add $url to custom/plugins/$path"
#     git submodule add -f $url custom/plugins/$path
# done <<< $(cat ~/linux_new_install/.omz_plugins)
mkdir -p $HOME/.config/zsh
export ZSH_HOME=$HOME/.config/zsh
export ZPLUG_HOME=$ZSH_HOME/zplug
git clone https://github.com/zplug/zplug $ZPLUG_HOME

cp -r ~/rasp_setup/.zshrc ~ || exit
super chsh -s /bin/zsh ubuntu || exit

#golang needed for hexokinase
super apt install golang-go -y
# super true # just to use sudo on the next lines
# wget -c https://golang.org/dl/go1.17.2.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
#nvim
cd ~
mkdir -p .config || exit
cp -r ~/linux_new_install/.config/nvim/ ~/.config/ || exit
cd ~/.config/nvim || exit
./update.sh || exit

#gitconfig
cp ~/rasp_setup/.gitconfig ~ || exit

#? MongoDB install
# Install the MongoDB 4.4 GPG key:
super true # just to use sudo on the next lines
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
# Add the source location for the MongoDB packages:
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list

# Download the package details for the MongoDB packages:
super apt-get update || exit
# Install MongoDB:
super apt-get install -y mongodb-org || exit
# Ensure mongod config is picked up:
super systemctl daemon-reload || exit
# Tell systemd to run mongod on reboot:
super systemctl enable mongod || exit
# Start up mongod!
super systemctl start mongod || exit

#? node stuff
super apt install -y npm || exit
super npm install -g n@latest
super n lts
super npm install nodemon pm2 -g

#? nginx stuff
super apt install -y nginx || exit
super systemctl enable nginx || exit
super systemctl start nginx || exit
super ufw enable || exit
super ufw default deny || exit
super ufw allow 80/tcp || exit
super ufw allow 443/tcp || exit
super ufw allow 22/tcp || exit
super cp -r ~/rasp_setup/sites-available /etc/nginx
super ln -sf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/

#? netdata stuff
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --stable-channel --disable-telemetry
sudo sed -i 's/# allow dashboard from = localhost */allow dashboard from = localhost 192.168.*/' /etc/netdata/netdata.conf || exit
sudo ufw allow 19999 || exit

#? tmux stuff
cp -r ~/linux_new_install/.tmux.conf ~/
cp -r ~/linux_new_install/.tmux/ ~/ #copies the plugin manager

#? reloading stuff
super ufw reload || exit

#? Follow up stuff
cp ~/rasp_setup/TODO_AFTER_INSTALL ~/

#? cleanup
super apt autoremove -y || exit
rm -rf ~/linux_new_install || exit
rm -rf ~/rasp_setup || exit
