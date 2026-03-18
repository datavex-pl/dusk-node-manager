# dusk-node-manager
Dusk Node Manager


A comprehensive bash script for managing Dusk Network provisioner nodes. This tool provides an easy-to-use menu interface for installing, configuring, and maintaining Dusk nodes, wallets, and staking operations.

https://img.shields.io/badge/version-4.1.0-blue
https://img.shields.io/badge/license-MIT-green
https://img.shields.io/badge/Dusk-Provisioner-orange

📋 Table of Contents
Features

Prerequisites

Quick Start

Installation

Menu Structure

Detailed Usage

Network Support

Fast Sync

Wallet Operations

Staking Guide

Troubleshooting

FAQ

Contributing

License

✨ Features
Guided Setup Assistant - Step-by-step node installation and configuration

Network Selection - Support for both Mainnet and Testnet

Node Management - Install, start, stop, restart, and update nodes

Fast Sync - Download state snapshots for quicker synchronization

Wallet Management - Create, restore, and manage wallets

Staking Operations - Stake, unstake, claim rewards, and view staking info

Multi-Profile Support - Handle multiple wallet profiles (0-10)

Transaction Tools - Transfer DUSK, shield/unshield tokens

Contract Deployment - Deploy and interact with smart contracts

Monitoring - View node status, logs, and sync progress

Firewall Configuration - Automatic UFW setup for required ports

Clean Installation - Complete removal option for fresh starts

📦 Prerequisites
Operating System: Ubuntu 24.04 LTS (recommended)

Hardware:

CPU: 2+ cores @ 2 GHz

RAM: 4+ GB

Storage: 50+ GB free space

Network: Open ports 22/tcp (SSH), 9000/udp (Kadcast), optional 8080/tcp

Sudo access for installations

🚀 Quick Start
bash
# Download the script
wget https://raw.githubusercontent.com/yourusername/dusk-node-manager/main/dusk-manager.sh

# Make it executable
chmod +x dusk-manager.sh

# Run the script
./dusk-manager.sh
💻 Installation
Option 1: Direct Download
bash
curl -O https://raw.githubusercontent.com/yourusername/dusk-node-manager/main/dusk-manager.sh
chmod +x dusk-manager.sh
./dusk-manager.sh
Option 2: Clone Repository
bash
git clone https://github.com/yourusername/dusk-node-manager.git
cd dusk-node-manager
chmod +x dusk-manager.sh
./dusk-manager.sh
🎮 Menu Structure
text
MAIN MENU
├── 1) Setup Assistant (Guided Setup)
├── 2) Node Management
│   ├── 1) Install Mainnet
│   ├── 2) Install Testnet
│   ├── 3) Start Node
│   ├── 4) Stop Node
│   ├── 5) Restart Node
│   ├── 6) Fast-Sync Node
│   ├── 7) Fast-Sync with Cleanup
│   ├── 8) List Available States
│   └── 9) Back
├── 3) Wallet & Staking
│   ├── 1) Create New Wallet
│   ├── 2) Restore Existing Wallet
│   ├── 3) List Profiles
│   ├── 4) Check Balance
│   ├── 5) Transaction History
│   ├── 6) Transfer DUSK
│   ├── 7) Shield DUSK
│   ├── 8) Unshield DUSK
│   ├── 9) Stake DUSK
│   ├── 10) Unstake DUSK
│   ├── 11) Staking Info
│   ├── 12) Claim Rewards
│   ├── 13) Deploy Contract
│   ├── 14) Call Contract
│   ├── 15) Calculate Contract ID
│   ├── 16) Send Blob
│   ├── 17) Export Consensus Keys
│   ├── 18) Set Keys Password
│   ├── 19) Show Settings
│   └── 20) Back
├── 4) Monitoring
│   ├── 1) Node Status
│   ├── 2) Live Logs
│   ├── 3) Recent Logs
│   ├── 4) Sync Status
│   └── 5) Back
├── 5) Configuration
│   ├── 1) Configure Firewall
│   ├── 2) System Information
│   └── 3) Back
├── 6) Clean Installation
└── 7) Exit
📚 Detailed Usage
🎯 Setup Assistant (Option 1)
The guided setup assistant walks you through the entire node setup process:

Select Network - Choose Mainnet or Testnet

Clean Installation - Optionally remove existing installation

Node Installation - Automatic download and installation

Wallet Setup - Create new or restore existing wallet

Key Export - Export consensus keys for provisioner

Password Setup - Set password for consensus keys

Node Start - Launch the node

Fast Sync - Optional snapshot download for faster sync

🌐 Network Support
The script supports both Dusk networks:

Mainnet: Production network with real DUSK tokens

Testnet: Testing network for experimentation

Installation commands:

Mainnet: curl ... | sudo bash

Testnet: curl ... | sudo bash -s -- --network testnet

⚡ Fast Sync
Significantly reduce sync time by downloading state snapshots:

bash
# List available snapshots
download_state --list

# Download latest state (automatically handled by script)
download_state

# Clean up if errors occur
sudo rm /tmp/state.tar.gz
The script provides two fast-sync options:

Fast-Sync Node: Standard snapshot download

Fast-Sync with Cleanup: Thorough cleanup before download

👛 Wallet Operations
Create New Wallet
bash
# Option 3 → 1
# Follow prompts to save your mnemonic phrase securely!
Restore Existing Wallet
bash
# Option 3 → 2
# Enter your 24-word mnemonic phrase when prompted
List Profiles
bash
# Option 3 → 3
# View all wallet profiles (0-10)
Check Balance
bash
# Option 3 → 4
# Display current wallet balance
Transaction History
bash
# Option 3 → 5
# View past transactions
💸 Transfer DUSK
bash
# Option 3 → 6
# Follow prompts for:
# - Recipient address
# - Amount to send
# - Profile selection (optional)
🛡️ Shield/Unshield Operations
bash
# Shield DUSK (public → shielded) - Option 3 → 7
# Unshield DUSK (shielded → public) - Option 3 → 8
📈 Staking Guide
Stake DUSK (Minimum 1000)
bash
# Option 3 → 9
# Options:
# 1) Stake from default wallet
# 2) Stake with custom owner address
Unstake DUSK
bash
# Option 3 → 10
# Confirm to unstake all
# Options for custom owner address
Staking Information
bash
# Option 3 → 11
# Select profile index (0-10)
# View stake details including:
# - Amount staked
# - Eligibility status
# - Rewards accumulated
Claim Rewards
bash
# Option 3 → 12
# Claim accumulated staking rewards
🔑 Key Management
Export Consensus Keys
bash
# Option 3 → 17
# Required for provisioner operation
# Exports to: /opt/dusk/conf/consensus.keys
Set Keys Password
bash
# Option 3 → 18
# Set password for consensus keys
# Required before node can start
📄 Contract Operations
Deploy Contract
bash
# Option 3 → 13
# Enter bytecode file path
# Optional: owner address, gas limit
Call Contract
bash
# Option 3 → 14
# Enter contract ID, function name
# Optional: arguments, gas limit
Calculate Contract ID
bash
# Option 3 → 15
# Calculate contract ID from bytecode
📦 Blob Transactions
bash
# Option 3 → 16
# Send blob data as hex string
📊 Monitoring
Node Status
bash
# Option 4 → 1
# View detailed node service status
Live Logs
bash
# Option 4 → 2
# Real-time log monitoring (Ctrl+C to exit)
Recent Logs
bash
# Option 4 → 3
# View last 50 lines of logs
Sync Status
bash
# Option 4 → 4
# Check current block height
# Compare with explorer
🔧 Configuration
Firewall Setup
bash
# Option 5 → 1
# Automatically configures UFW with:
# - Port 22/tcp (SSH)
# - Port 9000/udp (Kadcast)
# - Port 8080/tcp (HTTP, optional)
System Information
bash
# Option 5 → 2
# Display:
# - User info
# - OS version
# - CPU cores
# - RAM
# - Disk space
# - Installation paths
🧹 Clean Installation
bash
# Option 6
# Complete removal of:
# - Node binaries
# - Configuration files
# - Systemd service
# Optional wallet file removal
🔍 Troubleshooting
Common Issues
Node Won't Start
bash
# Check service status
sudo systemctl status rusk

# View logs
journalctl -u rusk -f

# Ensure consensus keys exist
ls -la /opt/dusk/conf/consensus.keys

# Verify password is set
ls -la /opt/dusk/conf/consensus.keys.pass
Fast Sync Fails
bash
# Clean up and retry
sudo rm /tmp/state.tar.gz
# Then run fast-sync again
Wallet Restore Issues
Ensure you have the correct 24-word mnemonic phrase

Check for typos in words

Verify word order

Port Conflicts
bash
# Check if ports are in use
sudo ss -tulpn | grep -E '9000|8080'
Logs Location
Systemd logs: journalctl -u rusk

Node logs: /var/log/rusk.log

Wallet data: ~/.dusk/rusk-wallet/

Configuration: /opt/dusk/conf/

❓ FAQ
Q: What is the minimum stake required?
A: Minimum stake is 1000 DUSK.

Q: Can I run multiple profiles?
A: Yes, profiles 0-10 are supported. Profile 0 is the default.

Q: How long does fast sync take?
A: Usually 10-30 minutes depending on network speed, compared to hours/days for full sync.

Q: Do I need to open ports in my firewall?
A: Yes, ports 22/tcp (SSH) and 9000/udp (Kadcast) are required. Port 8080/tcp is optional.

Q: Can I switch between Mainnet and Testnet?
A: Yes, but it requires a clean installation as they use different configurations.

Q: Where are my wallet files stored?
A: ~/.dusk/rusk-wallet/ for modern wallets, or ~/.dusk/wallet.dat for legacy.

Q: How do I backup my wallet?
A: Your mnemonic phrase is the primary backup. The script also offers wallet export (Option 3 → 9).

🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

Fork the repository

Create your feature branch (git checkout -b feature/AmazingFeature)

Commit your changes (git commit -m 'Add some AmazingFeature')

Push to the branch (git push origin feature/AmazingFeature)

Open a Pull Request

📝 License
This project is licensed under the MIT License - see the LICENSE file for details.

⚠️ Disclaimer
This tool is provided as-is. Always verify commands and ensure you have proper backups of your mnemonic phrases. The authors are not responsible for any loss of funds or data.

Made with ❤️ for the Dusk Network Community
