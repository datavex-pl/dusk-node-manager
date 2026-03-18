# 🚀 Dusk Node Manager

![Version](https://img.shields.io/badge/version-4.4.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Dusk](https://img.shields.io/badge/Dusk-Provisioner-orange)

A lightweight bash script to effortlessly install, configure, and manage a **Dusk Network provisioner node**.

---

## 📦 Prerequisites

- Ubuntu 24.04 LTS  
- 2+ CPU cores, 4+ GB RAM, 50+ GB free disk  
- Open ports: `22/tcp` (SSH), `9000/udp` (Kadcast) – optional: `8080/tcp`

---

## ⚡ Quick Install

```bash
wget https://raw.githubusercontent.com/datavex-pl/dusk-node-manager/main/dusk-manager.sh
chmod +x dusk-manager.sh
./dusk-manager.sh
```


The Setup Assistant will guide you through:

1. Network selection (Mainnet / Testnet)

2. Node installation (official installer)

3. Wallet creation or restoration

4. Consensus key export & password setup

5. Node start and optional fast‑sync

1) Setup Assistant   – Guided full node setup
2) Node Management   – Install, start, stop, restart, fast‑sync
3) Wallet & Staking  – Create/restore wallet, transfer, stake, etc.
4) Monitoring        – Status, logs, sync progress
5) Configuration     – Firewall, system info
6) Clean Installation– Remove everything (keep mnemonic safe!)
7) Exit

🔧 Basic Commands (after install)
What	Command
Start the node	      `sudo systemctl start rusk`
Stop the node	        `sudo systemctl stop rusk`
Check node status	    `systemctl status rusk`
Watch live logs	      `tail -F /var/log/rusk.log`
Wallet balance	      `rusk-wallet balance`
Stake 1000 DUSK	      `rusk-wallet stake --amt 1000`
Export consensus keys	`rusk-wallet export -d /opt/dusk/conf -n consensus.keys`

⚠️ Important Notes
Always backup your mnemonic phrase offline.

The script uses sudo only when necessary (installations, service control).

For security, you can review the script before running:
`less dusk-manager.sh`

Made with ❤️ for the Dusk community

## ☕ Support the Project

If you find this tool useful, consider buying us a coffee! Your support helps maintain and improve the script.

Or support via:
- **DUSK**: `25drmwGknQwYcBR7J3niDDanfX8CvVXNw3rG7dbBRbsHFFcxiy9kWUhwhJvFTsMvPtjisqigLzz2TN8XACaaNzyrT1mJbffkk7BSSrL3T6ebAKomuqEyerQ3JnnXGbAoRtro`

Every coffee keeps us coding! ☕

---


