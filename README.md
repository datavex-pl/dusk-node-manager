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


The Setup Assistant will guide you through:

1. Network selection (Mainnet / Testnet)

2. Node installation (official installer)

3. Wallet creation or restoration

4. Consensus key export & password setup

5. Node start and optional fast‑sync
