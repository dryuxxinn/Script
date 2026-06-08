#!/bin/bash

set -euo pipefail

echo "==========================================="
echo " OpenSCAP + SCAP Security Guide Installer"
echo " Ubuntu 24.04"
echo "==========================================="

# Pastikan dijalankan sebagai root

if [ "$EUID" -ne 0 ]; then
echo "[ERROR] Jalankan menggunakan sudo atau root."
exit 1
fi

echo
echo "[1/9] Update package repository..."
apt update

echo
echo "[2/9] Install dependencies..."
apt install -y 
openscap-scanner 
wget 
curl 
unzip 
ca-certificates

echo
echo "[3/9] Create working directories..."
mkdir -p /usr/share/xml/scap/ssg/content
mkdir -p /opt/scap-temp
mkdir -p /var/reports/openscap

cd /opt/scap-temp

echo
echo "[4/9] Clean old files..."
rm -f scap-security-guide.zip

echo
echo "[5/9] Download latest SCAP Security Guide..."
wget -O scap-security-guide.zip 
https://github.com/ComplianceAsCode/content/releases/latest/download/scap-security-guide.zip

echo
echo "[6/9] Verify ZIP archive..."
unzip -t scap-security-guide.zip >/dev/null

echo "[OK] ZIP validation passed."

echo
echo "[7/9] Extract files..."
rm -rf extracted
mkdir extracted
unzip -o scap-security-guide.zip -d extracted >/dev/null

echo
echo "[8/9] Search and install DataStream XML files..."

FOUND=$(find extracted -name "*-ds.xml" | wc -l)

if [ "$FOUND" -eq 0 ]; then
echo "[ERROR] No DataStream XML files found."
exit 1
fi

find extracted -name "*-ds.xml" 
-exec cp {} /usr/share/xml/scap/ssg/content/ ;

echo
echo "[9/9] Verify installation..."

echo
echo "Installed content:"
ls -lh /usr/share/xml/scap/ssg/content/

echo
echo "Ubuntu profiles available:"
find /usr/share/xml/scap/ssg/content -name "*ubuntu*.xml"

echo
echo "OpenSCAP version:"
oscap --version

echo
echo "Installation completed successfully."

echo
echo "Example command:"
echo "oscap info /usr/share/xml/scap/ssg/content/ssg-ubuntu2404-ds.xml"
