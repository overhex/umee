read -p "Enter node name: " UMEE_NODENAME
echo 'export UMEE_NODENAME='\"${UMEE_NODENAME}\" >> $HOME/.bash_profile

sudo apt update
sudo apt upgrade -y
sudo apt install make clang pkg-config libssl-dev build-essential git jq ncdu -y

wget -O go1.17.2.linux-amd64.tar.gz https://golang.org/dl/go1.17.2.linux-amd64.tar.gz

rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.2.linux-amd64.tar.gz && rm go1.17.2.linux-amd64.tar.gz

echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile

echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile

echo 'export GO111MODULE=on' >> $HOME/.bash_profile

echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile

go version

git clone --depth 1 --branch v0.3.0 https://github.com/umee-network/umee.git

cd umee && make install

umeed init ${UMEE_NODENAME} --chain-id=umeevengers-1c

rm /root/.umee/config/genesis.json

cd

echo "[Unit]
Description=Umee
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which umeed) start
Restart=on-failure
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target" > $HOME/umeed.service

mv umeed.service /etc/systemd/system

wget -O $HOME/.umee/config/genesis.json "https://raw.githubusercontent.com/umee-network/testnets/main/networks/umeevengers-1c/genesis.json"

umeed unsafe-reset-all

external_address=`curl ifconfig.me`  

echo $external_address

peers="1694e2cd89b03270577e547d7d84ebef13e4eff1@172.105.168.226:26656,4d50abb293f399a0f41ef9dbebe62615d4c85e42@3.34.147.65:26656,d2447c2ba201fb5bdd7250921c7c267af18c0950@94.130.23.149:26656,901a625ecf43014cc383239524c5eb6595a56888@135.181.165.110:26656,4ea1dc6af45f0fad7315029d181ada53f7d3174c@161.97.182.71:26656,60a11b328f161fe8f3f98f85e838addb07513c9e@46.101.234.47:26656,4bf9ff17d148418aec04fdda9bff671e482457a3@213.202.252.173:26656,1fb83420fd2bf665dc886fb3727d809579d63e51@206.189.133.102:26656,b85598b96a9c8e835b7b2f2c0b322eb2317fe7cd@94.250.201.70:26656"

sed -i.bak -e "s/^external_address = \"\"/external_address = \"$external_address:26656\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.umee/config/config.toml

systemctl enable umeed
systemctl restart umeed

journalctl -u umeed -f
