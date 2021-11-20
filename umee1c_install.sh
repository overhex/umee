#!/bin/bash

echo 'This will install umee node in umeevengers-1c chain'
echo 'Provide you node name and wait for installation ends'

read -p "Umee node name: " UMEE_NODENAME
echo 'export UMEE_NODENAME='\"${UMEE_NODENAME}\" >> $HOME/.bash_profile

sudo apt update
sudo apt upgrade -y
sudo apt install make clang pkg-config libssl-dev build-essential git jq ncdu -y

wget -O go1.17.2.linux-amd64.tar.gz https://golang.org/dl/go1.17.2.linux-amd64.tar.gz

sudo rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.2.linux-amd64.tar.gz && rm go1.17.2.linux-amd64.tar.gz

echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
source $HOME/.bash_profile

go version

git clone --depth 1 --branch v0.3.0 https://github.com/umee-network/umee.git

cd umee && sudo make install

umeed init ${UMEE_NODENAME} --chain-id=umeevengers-1c

rm $HOME/.umee/config/genesis.json
wget -O $HOME/.umee/config/genesis.json "https://raw.githubusercontent.com/umee-network/testnets/main/networks/umeevengers-1c/genesis.json"

cd $HOME

echo "[Unit]
Description=Umee
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which umeed) start
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/umeed.service

sudo mv $HOME/umeed.service /etc/systemd/system

sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF

umeed unsafe-reset-all

wget -O $HOME/.umee/config/addrbook.json "https://raw.githubusercontent.com/overhex/umee/main/addrbook-1c.json"

nodeIP=`curl ifconfig.me`  

echo 'Your node IP: '$nodeIP

peers="1694e2cd89b03270577e547d7d84ebef13e4eff1@172.105.168.226:26656,4d50abb293f399a0f41ef9dbebe62615d4c85e42@3.34.147.65:26656,d2447c2ba201fb5bdd7250921c7c267af18c0950@94.130.23.149:26656,901a625ecf43014cc383239524c5eb6595a56888@135.181.165.110:26656,4ea1dc6af45f0fad7315029d181ada53f7d3174c@161.97.182.71:26656,60a11b328f161fe8f3f98f85e838addb07513c9e@46.101.234.47:26656,4bf9ff17d148418aec04fdda9bff671e482457a3@213.202.252.173:26656,1fb83420fd2bf665dc886fb3727d809579d63e51@206.189.133.102:26656,b85598b96a9c8e835b7b2f2c0b322eb2317fe7cd@94.250.201.70:26656"

sed -i.bak -e "s/^nodeIP = \"\"/nodeIP = \"$nodeIP:26656\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.umeed/config/config.toml

sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable umeed
sudo systemctl restart umeed

echo ''
echo 'Install finished!'
echo 'For environments run' 
echo 'source $HOME/.bash_profile'
echo 'For log view run'
echo 'journalctl -u umeed -f'
