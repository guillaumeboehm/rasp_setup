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

super apt install -y zsh || exit
cd ~
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || exit
cp -r ~/rasp_setup/.zshrc ~ || exit
super chsh -s /bin/zsh ubuntu || exit

#? MongoDB install

# Install the MongoDB 4.4 GPG key:
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | super apt-key add -
# Add the source location for the MongoDB packages:
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | super tee /etc/apt/sources.list.d/mongodb-org-4.4.list

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

super apt install -y nodejs npm || exit
