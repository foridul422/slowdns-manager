#!/bin/bash
# ====================================================================
# Installer & Auto-Repair Suite for SlowDNS & SSH User Manager
# ====================================================================

set -e

echo "[*] Step 1: Stopping conflicting DNS services..."
systemctl stop dnsdist 2>/dev/null || true
systemctl disable dnsdist 2>/dev/null || true

echo "[*] Step 2: Fixing OpenSSH Server & Disabling Socket Conflicts..."
systemctl disable --now ssh.socket 2>/dev/null || true
rm -f /etc/ssh/sshd_config.d/99-vpn-tune.conf

cat > /etc/ssh/sshd_config.d/00-custom.conf << 'EOF'
Port 22
Port 22022
PermitRootLogin yes
PasswordAuthentication yes
AllowTcpForwarding yes
GatewayPorts yes
X11Forwarding no
MaxStartups 1000:30:2000
MaxSessions 1000
MaxAuthTries 10
ClientAliveInterval 30
ClientAliveCountMax 3
UseDNS no
TCPKeepAlive yes
Compression no
EOF

systemctl restart ssh.service || systemctl restart ssh
echo "[+] OpenSSH configured and running on Port 22 & 22022"

echo "[*] Step 3: Configuring HAProxy Multiplexer (No Spam Checks)..."
mkdir -p /etc/haproxy
cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    daemon
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    maxconn 4096

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    retries 3
    timeout connect 5s
    timeout client  1m
    timeout server  1m

frontend slowdns_in
    bind 127.0.0.1:10000
    mode tcp
    tcp-request inspect-delay 1s
    acl is_ssh req.payload(0,4) -m str SSH-
    use_backend backend_ssh if is_ssh
    default_backend backend_v2ray

backend backend_ssh
    mode tcp
    server srv_ssh 127.0.0.1:22

backend backend_v2ray
    mode tcp
    server srv_v2ray 127.0.0.1:10086
EOF

systemctl restart haproxy 2>/dev/null || true
systemctl enable haproxy 2>/dev/null || true

echo "[*] Step 4: Ensuring BadVPN UDPGW Service (Gaming/UDP)..."
cat > /etc/systemd/system/badvpn-udpgw.service << 'EOF'
[Unit]
Description=BadVPN UDPGW Service for SSH Gaming/VoIP
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 100
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable badvpn-udpgw 2>/dev/null || true
systemctl restart badvpn-udpgw 2>/dev/null || true

echo "[*] Step 5: Configuring SlowDNS Server (Port 53)..."
cat > /etc/systemd/system/slowdns.service << 'EOF'
[Unit]
Description=DNSTT SlowDNS Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dnstt-server -udp :53 -privkey-file /etc/slowdns/server.key dns.foridul.pp.ua 127.0.0.1:10000
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable slowdns
systemctl restart slowdns

echo "[*] Step 6: Installing User Management Commands..."
mkdir -p /etc/slowdns/users
mkdir -p /usr/local/bin

REPO_RAW="https://raw.githubusercontent.com/foridul422/slowdns-manager/main"

for script in addssh trialssh renewssh delssh userssh onlinessh autokillssh menu; do
    curl -sL "$REPO_RAW/$script" -o "/usr/local/bin/$script"
    chmod +x "/usr/local/bin/$script"
    echo "[+] Installed: /usr/local/bin/$script"
done

# Create convenience symlinks
ln -sf /usr/local/bin/addssh /usr/local/bin/usernew
ln -sf /usr/local/bin/trialssh /usr/local/bin/trial
ln -sf /usr/local/bin/renewssh /usr/local/bin/renew
ln -sf /usr/local/bin/delssh /usr/local/bin/hapus
ln -sf /usr/local/bin/userssh /usr/local/bin/member
ln -sf /usr/local/bin/onlinessh /usr/local/bin/cek

# Setup automated cronjob
cat > /etc/cron.d/slowdns-autokill << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/10 * * * * root /usr/local/bin/autokillssh >/dev/null 2>&1
EOF
chmod 644 /etc/cron.d/slowdns-autokill

# Add greeting helper in /root/.bashrc if not present
if ! grep -q "alias menu=" /root/.bashrc 2>/dev/null; then
    echo "alias menu='/usr/local/bin/menu'" >> /root/.bashrc
fi

echo ""
echo "=================================================================="
echo "  🎉 SLOWDNS & SSH USER MANAGER INSTALLED & REPAIRED SUCCESSFULLY!"
echo "=================================================================="
echo "  Type: menu        (to open interactive management menu)"
echo "  Type: addssh      (to create new user)"
echo "  Type: trialssh    (to create 24h trial user)"
echo "  Type: userssh     (to list all users)"
echo "=================================================================="
