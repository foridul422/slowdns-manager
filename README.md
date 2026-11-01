# SlowDNS & SSH Multi-Protocol User Manager
A fast, automated user management suite for SSH over SlowDNS (DNSTT) on Linux VPS.

## Features
- **Restricted Users**: Accounts are created with `/bin/false` shell (Tunneling only, no interactive command execution).
- **Auto Expiration**: Automatic date calculation and account locking after expiry.
- **24-Hour Trial Generator**: One-click free trial account generator.
- **Multi-Login Limiter**: Enforces device connection limits (1 or 2 devices) and terminates excess sessions.
- **Auto Cleanup**: Background cronjob automatically removes expired accounts.
- **Interactive Terminal Menu**: Run `menu` for full GUI-like CLI controls.

## 1-Command Installation on VPS
```bash
bash <(curl -sL https://raw.githubusercontent.com/foridul422/slowdns-manager/main/install.sh)
```

## Available Commands
- `menu` - Interactive management dashboard
- `addssh` / `usernew` - Create new SSH user
- `trialssh` / `trial` - Generate 24H trial user
- `renewssh` / `renew` - Extend user validity
- `delssh` / `hapus` - Delete user account
- `userssh` / `member` - List all accounts & expiry
- `onlinessh` / `cek` - View connected online users
