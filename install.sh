#!/bin/bash
# ====================================================================
# Installer for SlowDNS & SSH User Manager Suite
# ====================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[+] Installing SlowDNS & SSH User Manager..."

mkdir -p /etc/slowdns/users
mkdir -p /usr/local/bin

REPO_RAW="https://raw.githubusercontent.com/foridul422/slowdns-manager/main"

for script in addssh trialssh renewssh delssh userssh onlinessh autokillssh menu; do
    if [ -f "$DIR/$script" ]; then
        cp -f "$DIR/$script" "/usr/local/bin/$script"
    else
        curl -sL "$REPO_RAW/$script" -o "/usr/local/bin/$script"
    fi
    chmod +x "/usr/local/bin/$script"
    echo "[+] Installed: /usr/local/bin/$script"
done

# Create aliases / convenience links
ln -sf /usr/local/bin/addssh /usr/local/bin/usernew
ln -sf /usr/local/bin/trialssh /usr/local/bin/trial
ln -sf /usr/local/bin/renewssh /usr/local/bin/renew
ln -sf /usr/local/bin/delssh /usr/local/bin/hapus
ln -sf /usr/local/bin/userssh /usr/local/bin/member
ln -sf /usr/local/bin/onlinessh /usr/local/bin/cek

# Setup automated cronjob (Runs every 10 minutes to kill multi-logins and delete expired accounts)
cat > /etc/cron.d/slowdns-autokill <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/10 * * * * root /usr/local/bin/autokillssh >/dev/null 2>&1
EOF
chmod 644 /etc/cron.d/slowdns-autokill

# Add greeting helper in /root/.bashrc if not present
if ! grep -q "alias menu=" /root/.bashrc 2>/dev/null; then
    echo "alias menu='/usr/local/bin/menu'" >> /root/.bashrc
fi

echo "[+] SlowDNS & SSH User Manager installed successfully!"
echo "[+] Type 'menu' anytime to manage your VPN users!"
