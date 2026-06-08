#!/bin/bash

set -euo pipefail

echo "=================================="
echo " Ubuntu Full Stack Installer"
echo " Angular + NestJS + MongoDB"
echo " Nginx + Kong Gateway"
echo "=================================="

if [ "$EUID" -ne 0 ]; then
echo "Jalankan script sebagai root"
exit 1
fi

UBUNTU_CODENAME=$(lsb_release -cs)

echo "[1/8] Update System..."
apt update
apt upgrade -y

echo "[2/8] Install Dependencies..."
apt install -y 
curl 
wget 
gnupg 
gpg 
lsb-release 
ca-certificates 
software-properties-common 
apt-transport-https

#################################################

# NODEJS

#################################################

echo "[3/8] Install NodeJS LTS..."

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -

apt install -y nodejs

echo "Node Version:"
node -v

echo "NPM Version:"
npm -v

#################################################

# ANGULAR

#################################################

echo "[4/8] Install Angular CLI..."

npm install -g @angular/cli

#################################################

# NESTJS

#################################################

echo "[5/8] Install NestJS CLI..."

npm install -g @nestjs/cli

#################################################

# MONGODB

#################################################

echo "[6/8] Install MongoDB 8.0..."

rm -f /etc/apt/sources.list.d/mongodb-org.list

wget -qO - https://pgp.mongodb.com/server-8.0.asc 
| gpg --dearmor 
-o /usr/share/keyrings/mongodb-server.gpg

echo "deb [ signed-by=/usr/share/keyrings/mongodb-server.gpg ] https://repo.mongodb.org/apt/ubuntu ${UBUNTU_CODENAME}/mongodb-org/8.0 multiverse" \

> /etc/apt/sources.list.d/mongodb-org.list

apt update
apt install -y mongodb-org

systemctl enable mongod --now

#################################################

# NGINX

#################################################

echo "[7/8] Install Nginx..."

apt install -y nginx

systemctl unmask nginx 2>/dev/null || true
systemctl enable nginx --now

#################################################

# KONG

#################################################

echo "[8/8] Install Kong Gateway 3.14..."

rm -f /etc/apt/sources.list.d/*kong*

curl -1sLf 
"https://packages.konghq.com/public/gateway-314/gpg.1B7E2AF3C3BF8153.key" 
| gpg --dearmor 
| tee /usr/share/keyrings/kong-gateway-314-archive-keyring.gpg >/dev/null

curl -1sLf 
"https://packages.konghq.com/public/gateway-314/config.deb.txt?distro=ubuntu&codename=${UBUNTU_CODENAME}" 
| tee /etc/apt/sources.list.d/kong-gateway-314.list >/dev/null

apt update

apt install -y kong-enterprise-edition

if ! command -v kong >/dev/null 2>&1; then
echo "ERROR: Kong gagal terinstall"
exit 1
fi

mkdir -p /etc/kong

if [ ! -f /etc/kong/kong.conf ]; then
cp /etc/kong/kong.conf.default /etc/kong/kong.conf
fi

sed -i 's/^#database.*/database = off/' /etc/kong/kong.conf

grep -q "^proxy_listen" /etc/kong/kong.conf || 
echo "proxy_listen = 0.0.0.0:8000" >> /etc/kong/kong.conf

grep -q "^admin_listen" /etc/kong/kong.conf || 
echo "admin_listen = 0.0.0.0:8001" >> /etc/kong/kong.conf

kong start -c /etc/kong/kong.conf || true

#################################################

# FIREWALL

#################################################

echo ""
echo "Configuring Firewall..."
echo ""

PORTS=(
22
80
443
3000
8000
8001
8443
8444
27017
)

if systemctl is-active --quiet firewalld; then

```
echo "Detected Firewalld"

for p in "${PORTS[@]}"
do
    firewall-cmd --permanent --add-port=${p}/tcp
done

firewall-cmd --reload
```

elif command -v ufw >/dev/null 2>&1; then

```
echo "Detected UFW"

for p in "${PORTS[@]}"
do
    ufw allow ${p}/tcp
done

yes | ufw enable
```

elif command -v nft >/dev/null 2>&1; then

```
echo "Detected nftables"

if nft list table inet filter >/dev/null 2>&1; then
    nft add rule inet filter input tcp dport {22,80,443,3000,8000,8001,8443,8444,27017} accept 2>/dev/null || true
    nft list ruleset > /etc/nftables.conf
fi

systemctl enable nftables --now || true
```

else

```
echo "Firewall tidak ditemukan."
```

fi

#################################################

# STATUS

#################################################

echo ""
echo "=================================="
echo " INSTALASI SELESAI"
echo "=================================="

echo ""
echo "NodeJS:"
node -v

echo ""
echo "Angular:"
ng version || true

echo ""
echo "NestJS:"
nest --version || true

echo ""
echo "MongoDB:"
systemctl is-active mongod

echo ""
echo "Nginx:"
systemctl is-active nginx

echo ""
echo "Kong:"
kong version || true

echo ""
echo "Listening Ports:"
ss -tulpn

echo ""
echo "Done."
