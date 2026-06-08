#!/bin/bash

set -e

echo "=================================="
echo " Ubuntu Full Stack Installer"
echo " Angular + NestJS + MongoDB"
echo " Nginx + Kong Gateway"
echo "=================================="

if [ "$EUID" -ne 0 ]; then
    echo "Jalankan sebagai root atau sudo"
    exit 1
fi

echo "[1/8] Update System..."
apt update
apt upgrade -y

echo "[2/8] Install Dependencies..."
apt install -y \
curl \
wget \
gnupg \
lsb-release \
ca-certificates \
software-properties-common \
apt-transport-https

#################################################
# NODEJS
#################################################

echo "[3/8] Install NodeJS LTS..."

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

node -v
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

echo "[6/8] Install MongoDB..."

wget -qO - https://pgp.mongodb.com/server-8.0.asc \
| gpg --dearmor -o /usr/share/keyrings/mongodb-server.gpg

echo \
"deb [ signed-by=/usr/share/keyrings/mongodb-server.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/8.0 multiverse" \
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

echo "[8/8] Install Kong Gateway..."

curl -fsSL https://download.konghq.com/gateway-3.x-ubuntu/pool/all/k/kong/kong_3.8.0_amd64.deb \
-o /tmp/kong.deb

dpkg -i /tmp/kong.deb || apt -f install -y

echo "database=off" > /etc/kong/kong.conf

kong start || true

#################################################
# FIREWALL DETECTION
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
27017
)

if systemctl is-active --quiet firewalld; then

    echo "Detected Firewalld"

    for p in "${PORTS[@]}"
    do
        firewall-cmd --permanent --add-port=${p}/tcp
    done

    firewall-cmd --reload

elif command -v ufw >/dev/null 2>&1; then

    echo "Detected UFW"

    for p in "${PORTS[@]}"
    do
        ufw allow ${p}/tcp
    done

    yes | ufw enable

elif command -v nft >/dev/null 2>&1; then

    echo "Detected nftables"

    nft add rule inet filter input tcp dport {22,80,443,3000,8000,8001,27017} accept 2>/dev/null || true

    nft list ruleset > /etc/nftables.conf

    systemctl enable nftables --now

else

    echo "Firewall tidak ditemukan."
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
systemctl status mongod --no-pager -l | head

echo ""
echo "Nginx:"
systemctl status nginx --no-pager -l | head

echo ""
echo "Open Ports:"
ss -tulpn
