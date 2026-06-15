#!/bin/bash

set -e

LOGFILE="/var/log/fullstack-installer.log"

exec > >(tee -a "$LOGFILE")
exec 2>&1

echo "=================================================="
echo " Full Stack Installer"
echo " Angular + NestJS + MongoDB + Nginx + Kong"
echo "=================================================="

if [ "$EUID" -ne 0 ]; then
    echo "Jalankan script sebagai root atau sudo"
    exit 1
fi

SUCCESS=()
FAILED=()

record_success() {
    SUCCESS+=("$1")
}

record_failed() {
    FAILED+=("$1")
}

echo ""
echo "[1/10] Update System"

apt update -y
apt upgrade -y

echo ""
echo "[2/10] Install Dependencies"

apt install -y \
curl \
wget \
gnupg \
gpg \
ca-certificates \
lsb-release \
software-properties-common \
apt-transport-https \
unzip \
firewalld

systemctl enable firewalld
systemctl start firewalld

echo ""
echo "[3/10] Install Node.js LTS"

if curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -; then
    if apt install -y nodejs; then
        record_success "Node.js"
    else
        record_failed "Node.js"
    fi
else
    record_failed "NodeSource Repository"
fi

echo ""
echo "[4/10] Install Angular CLI"

if npm install -g @angular/cli; then
    record_success "Angular CLI"
else
    record_failed "Angular CLI"
fi

echo ""
echo "[5/10] Install NestJS CLI"

if npm install -g @nestjs/cli; then
    record_success "NestJS CLI"
else
    record_failed "NestJS CLI"
fi

echo ""
echo "[6/10] Install MongoDB"

curl -fsSL https://pgp.mongodb.com/server-8.0.asc \
| gpg --dearmor -o /usr/share/keyrings/mongodb-server.gpg

UBUNTU_CODENAME=$(lsb_release -cs)

echo "deb [ signed-by=/usr/share/keyrings/mongodb-server.gpg ] https://repo.mongodb.org/apt/ubuntu ${UBUNTU_CODENAME}/mongodb-org/8.0 multiverse" \
> /etc/apt/sources.list.d/mongodb-org.list

apt update

if apt install -y mongodb-org; then
    systemctl enable mongod
    systemctl restart mongod
    record_success "MongoDB"
else
    record_failed "MongoDB"
fi

echo ""
echo "[7/10] Install Nginx"

if apt install -y nginx; then
    systemctl enable nginx
    systemctl restart nginx
    record_success "Nginx"
else
    record_failed "Nginx"
fi

echo ""
echo "[8/10] Install Kong Gateway"

curl -fsSL https://packages.konghq.com/public/gateway-3/gpg.key \
| gpg --dearmor -o /usr/share/keyrings/kong.gpg

echo "deb [signed-by=/usr/share/keyrings/kong.gpg] https://packages.konghq.com/public/gateway-3/deb/ubuntu ${UBUNTU_CODENAME} main" \
> /etc/apt/sources.list.d/kong.list

apt update

if apt install -y kong; then
    record_success "Kong Gateway"
else
    record_failed "Kong Gateway"
fi

echo ""
echo "[9/10] Configure Firewall Dynamically"

sleep 5

LISTEN_PORTS=$(ss -lnt | awk 'NR>1 {print $4}' | grep -oE '[0-9]+$' | sort -u)

for PORT in $LISTEN_PORTS
do
    case "$PORT" in
        27017|27018|27019|3306|5432|6379|9200|9300)
            echo "Skipping sensitive port $PORT"
            continue
            ;;
    esac

    echo "Opening TCP port $PORT"
    firewall-cmd --permanent --add-port=${PORT}/tcp >/dev/null 2>&1 || true
done

firewall-cmd --reload

echo ""
echo "[10/10] Collect Information"

echo ""
echo "=================================================="
echo " INSTALLATION SUMMARY"
echo "=================================================="

echo ""
echo "SUCCESS"

for ITEM in "${SUCCESS[@]}"
do
    echo "  ✓ $ITEM"
done

echo ""

if [ ${#FAILED[@]} -gt 0 ]; then
    echo "FAILED"

    for ITEM in "${FAILED[@]}"
    do
        echo "  ✗ $ITEM"
    done
else
    echo "No failures detected"
fi

echo ""
echo "=================================================="
echo " VERSION INFORMATION"
echo "=================================================="

echo ""
echo "Node.js:"
node -v || true

echo ""
echo "NPM:"
npm -v || true

echo ""
echo "Angular:"
ng version || true

echo ""
echo "NestJS:"
nest --version || true

echo ""
echo "MongoDB:"
mongod --version | head -n 1 || true

echo ""
echo "Nginx:"
nginx -v || true

echo ""
echo "Kong:"
kong version || true

echo ""
echo "=================================================="
echo " FIREWALL PORTS"
echo "=================================================="

firewall-cmd --list-ports

echo ""
echo "=================================================="
echo " SERVICES"
echo "=================================================="

systemctl is-active nginx || true
systemctl is-active mongod || true
systemctl is-active firewalld || true

echo ""
echo "Log File:"
echo "$LOGFILE"

echo ""
echo "Installation Completed."
