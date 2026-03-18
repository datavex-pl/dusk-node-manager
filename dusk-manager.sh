#!/usr/bin/env bash

# Dusk Network Provisioner Node Management Script
# Version: 4.3.0 - Fixed curl | sudo bash compatibility
# Repository: https://github.com/datavex-pl/dusk-node-manager

# ============================================
# SAFETY CHECKS FOR CURL | BASH
# ============================================

# Exit on error, undefined variable, and pipe failure
set -euo pipefail

# Check if script is being run with sudo and handle it gracefully
if [[ $EUID -eq 0 ]]; then
    # Check if SUDO_USER exists (we're in a sudo environment)
    if [[ -n "${SUDO_USER:-}" ]]; then
        # We're running via sudo, but we want to drop privileges for the menu
        echo -e "\033[0;33m⚠️  Detected sudo execution. Dropping to normal user for menu...\033[0m"
        # Re-launch the script as the original user
        exec sudo -u "$SUDO_USER" bash "$0" "$@"
        exit 0
    else
        # We're actually root (not via sudo)
        echo -e "\033[0;31m❌ This script should not be run as root directly.\033[0m"
        echo -e "\033[0;33mPlease run it as a normal user (sudo will be prompted when needed).\033[0m"
        exit 1
    fi
fi

# Check for interactive terminal
if [[ ! -t 0 ]]; then
    echo "This script must be run interactively"
    exit 1
fi

# ============================================
# CONFIGURATION AND GLOBAL VARIABLES
# ============================================

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

# Icons
readonly ICON_SUCCESS="✅"
readonly ICON_ERROR="❌"
readonly ICON_WARNING="⚠️"
readonly ICON_INFO="ℹ️"
readonly ICON_NODE="🖥️"
readonly ICON_STAKE="💰"
readonly ICON_MONITOR="📊"
readonly ICON_SETTINGS="⚙️"
readonly ICON_MENU="📋"
readonly ICON_WALLET="👛"
readonly ICON_NETWORK="🌐"
readonly ICON_KEY="🔑"
readonly ICON_STEP="📝"
readonly ICON_ROCKET="🚀"
readonly ICON_CLEAN="🧹"
readonly ICON_USER="👤"
readonly ICON_PROFILE="📌"
readonly ICON_OWNER="👤"
readonly ICON_HISTORY="📜"
readonly ICON_TRANSFER="💸"
readonly ICON_SHIELD="🛡️"
readonly ICON_CONTRACT="📄"
readonly ICON_BLOB="📦"
readonly ICON_SYNC="🔄"
readonly ICON_DOWNLOAD="⬇️"

# Get current user dynamically (handle sudo case)
if [[ -n "${SUDO_USER:-}" ]]; then
    readonly CURRENT_USER="$SUDO_USER"
    readonly CURRENT_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    readonly CURRENT_USER=$(whoami)
    readonly CURRENT_HOME="$HOME"
fi

# Installation paths
readonly DUSK_INSTALL_DIR="/opt/dusk"
readonly DUSK_BIN="$DUSK_INSTALL_DIR/bin"
readonly DUSK_CONF="$DUSK_INSTALL_DIR/conf"
readonly DUSK_SERVICES="$DUSK_INSTALL_DIR/services"
readonly WALLET_DIR="$CURRENT_HOME/.dusk"
readonly RUSK_WALLET_DIR="$WALLET_DIR/rusk-wallet"

# Config file
readonly CONFIG_DIR="$CURRENT_HOME/.dusk-manager"
readonly CONFIG_FILE="$CONFIG_DIR/node.conf"

# Temp file for profile index
readonly PROFILE_TEMP_FILE="/tmp/dusk_profile_idx_$CURRENT_USER"

# Installer URL
readonly INSTALLER_URL="https://github.com/dusk-network/node-installer/releases/latest/download/node-installer.sh"

# ============================================
# INITIALIZATION
# ============================================

init_directories() {
    mkdir -p "$CONFIG_DIR"
    touch "$CONFIG_FILE"
}

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║         DUSK NETWORK PROVISIONER NODE MANAGER           ║"
    echo "║                    Version 4.3.0                        ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}System Time: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}User: ${GREEN}$CURRENT_USER${NC}"
    echo -e "${BLUE}Node Status: $(check_node_status)${NC}"
    echo -e "${BLUE}Network: $(get_network_config)${NC}"
    echo -e "${BLUE}Rusk Version: $(check_rusk_version)${NC}"
    echo -e "${BLUE}Wallet: $(check_wallet_status)${NC}"
    echo -e "${BLUE}Consensus Keys: $(check_keys_status)${NC}"
    echo "──────────────────────────────────────────────────────────"
}

# ============================================
# STATUS CHECK FUNCTIONS
# ============================================

get_network_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE" 2>/dev/null
        echo -e "${GREEN}${NETWORK:-not configured}${NC}"
    else
        echo -e "${RED}not configured${NC}"
    fi
}

check_node_status() {
    if systemctl is-active --quiet rusk 2>/dev/null; then
        echo -e "${GREEN}Running${NC}"
    else
        echo -e "${RED}Stopped${NC}"
    fi
}

check_rusk_version() {
    if command -v rusk &> /dev/null; then
        local version=$(rusk --version 2>/dev/null | head -n1 | cut -d' ' -f2)
        echo -e "${GREEN}${version:-installed}${NC}"
    else
        echo -e "${RED}Not installed${NC}"
    fi
}

check_wallet_status() {
    if [[ -d "$RUSK_WALLET_DIR" ]] && [[ -n "$(ls -A "$RUSK_WALLET_DIR" 2>/dev/null)" ]]; then
        echo -e "${GREEN}Configured${NC}"
    elif [[ -f "$WALLET_DIR/wallet.dat" ]]; then
        echo -e "${GREEN}Configured (legacy)${NC}"
    else
        echo -e "${RED}Not configured${NC}"
    fi
}

check_keys_status() {
    if [[ -f "$DUSK_CONF/consensus.keys" ]] && [[ -s "$DUSK_CONF/consensus.keys" ]]; then
        echo -e "${GREEN}Present${NC}"
    else
        echo -e "${RED}Missing${NC}"
    fi
}

check_node_installed() {
    if [[ -d "$DUSK_INSTALL_DIR" ]] && [[ -f "$DUSK_BIN/rusk" ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================
# FAST-SYNC FUNCTIONS
# ============================================

list_available_states() {
    echo -e "${YELLOW}${ICON_SYNC} Available Published States${NC}"
    echo "──────────────────────────────────────────────────────────"
    echo -e "${ICON_INFO} This will show all available state snapshots from Dusk archive nodes${NC}"
    echo

    if ! command -v download_state &> /dev/null; then
        echo -e "${RED}download_state command not found. Is node installed?${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi

    download_state --list

    echo
    read -p "Press Enter to continue..."
}

fast_sync_node() {
    echo -e "${YELLOW}${ICON_DOWNLOAD} Fast-Sync Node${NC}"
    echo "──────────────────────────────────────────────────────────"
    echo -e "${ICON_INFO} This will stop your node and replace its current state with the latest${NC}"
    echo -e "${ICON_INFO} published state from Dusk's archive nodes, significantly reducing sync time.${NC}"
    echo

    if ! command -v download_state &> /dev/null; then
        echo -e "${RED}download_state command not found. Is node installed?${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi

    # Check if node is running and stop it
    if systemctl is-active --quiet rusk; then
        echo -e "${YELLOW}Stopping node before fast-sync...${NC}"
        sudo systemctl stop rusk
        sleep 2
        echo -e "${GREEN}✓ Node stopped${NC}"
    fi

    # Clean up any previous state remnants
    echo -e "\n${YELLOW}Cleaning up previous state remnants...${NC}"
    if [[ -f /tmp/state.tar.gz ]]; then
        sudo rm /tmp/state.tar.gz
        echo -e "${GREEN}✓ Removed /tmp/state.tar.gz${NC}"
    fi

    echo -e "\n${YELLOW}Downloading latest state (this may take a while)...${NC}"
    echo -e "${ICON_INFO} The download_state command will show progress${NC}"
    echo

    read -p "Press Enter to start downloading the latest state..."

    # Run download_state
    download_state

    local download_status=$?

    if [[ $download_status -eq 0 ]]; then
        echo -e "\n${GREEN}${ICON_SUCCESS} State download completed successfully!${NC}"

        echo -e "\n${YELLOW}Starting node with new state...${NC}"
        sudo systemctl start rusk
        sleep 2

        if systemctl is-active --quiet rusk; then
            echo -e "${GREEN}✓ Node started successfully${NC}"
            echo -e "\n${CYAN}Your node is now syncing from the latest snapshot.${NC}"
            echo -e "${CYAN}This will be much faster than syncing from genesis.${NC}"
        else
            echo -e "${RED}Failed to start node. Please check logs.${NC}"
        fi
    else
        echo -e "\n${RED}${ICON_ERROR} State download failed${NC}"
        echo -e "${YELLOW}Common issues:${NC}"
        echo "  • Network connectivity problems"
        echo "  • Disk space issues"
        echo "  • Permission problems with /tmp directory"
    fi

    read -p "Press Enter to continue..."
}

fast_sync_with_cleanup() {
    echo -e "${YELLOW}${ICON_DOWNLOAD} Fast-Sync with Cleanup${NC}"
    echo "──────────────────────────────────────────────────────────"
    echo -e "${ICON_INFO} This will perform a thorough cleanup before fast-syncing.${NC}"
    echo

    if ! command -v download_state &> /dev/null; then
        echo -e "${RED}download_state command not found. Is node installed?${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi

    # Stop node if running
    if systemctl is-active --quiet rusk; then
        echo -e "${YELLOW}Stopping node...${NC}"
        sudo systemctl stop rusk
        sleep 2
    fi

    # Clean up any previous state remnants
    echo -e "\n${YELLOW}Performing thorough cleanup...${NC}"
    sudo rm -f /tmp/state.tar.gz
    sudo rm -rf /tmp/dusk-state-* 2>/dev/null
    echo -e "${GREEN}✓ Cleaned up temporary files${NC}"

    echo -e "\n${YELLOW}Downloading latest state...${NC}"
    download_state

    if [[ $? -eq 0 ]]; then
        echo -e "\n${GREEN}${ICON_SUCCESS} State download completed!${NC}"

        echo -e "\n${YELLOW}Starting node...${NC}"
        sudo systemctl start rusk

        if systemctl is-active --quiet rusk; then
            echo -e "${GREEN}✓ Node started successfully${NC}"
        fi
    else
        echo -e "\n${RED}${ICON_ERROR} State download failed${NC}"
    fi

    read -p "Press Enter to continue..."
}

# ============================================
# CLEAN INSTALLATION
# ============================================

clean_installation() {
    echo -e "${YELLOW}${ICON_CLEAN} Cleaning up existing installation...${NC}"

    sudo systemctl stop rusk 2>/dev/null
    sudo systemctl disable rusk 2>/dev/null
    sudo rm -f /etc/systemd/system/rusk.service
    sudo systemctl daemon-reload

    sudo rm -rf "$DUSK_INSTALL_DIR"
    sudo rm -f /usr/local/bin/rusk
    sudo rm -f /usr/local/bin/rusk-wallet
    sudo rm -f /usr/local/bin/ruskquery
    sudo rm -f /usr/local/bin/ruskreset

    echo -e "${GREEN}${ICON_SUCCESS} Cleanup complete${NC}"
}

# ============================================
# PROFILE SELECTION FUNCTION (USING TEMP FILE)
# ============================================

get_profile_idx() {
    local default_idx=${1:-0}
    local profile_input

    # Prompt user
    echo
    echo -e "${CYAN}Select profile index (0-10):${NC}"
    echo -e "${YELLOW}Profile 0 is the default wallet profile.${NC}"
    echo -e "${YELLOW}Additional profiles (1-10) can be created for different keys.${NC}"
    echo
    read -p "Enter profile index [0-10] (default: $default_idx): " profile_input

    # Set default if empty
    profile_input=${profile_input:-$default_idx}

    # Validate input
    if [[ ! "$profile_input" =~ ^[0-9]+$ ]] || [[ "$profile_input" -lt 0 ]] || [[ "$profile_input" -gt 10 ]]; then
        echo -e "${RED}Invalid profile index. Using $default_idx.${NC}"
        profile_input=$default_idx
        sleep 1
    fi

    # Write to temp file
    echo "$profile_input" > "$PROFILE_TEMP_FILE"
}

read_profile_idx() {
    if [[ -f "$PROFILE_TEMP_FILE" ]]; then
        local value=$(cat "$PROFILE_TEMP_FILE" | tr -d '\n' | tr -d '\r')
        rm -f "$PROFILE_TEMP_FILE"
        echo "$value"
    else
        echo "0"
    fi
}

# ============================================
# WALLET MANAGEMENT FUNCTIONS
# ============================================

create_wallet() {
    echo -e "${YELLOW}${ICON_WALLET} Creating new wallet...${NC}"
    echo -e "${RED}${ICON_WARNING} You will be shown a mnemonic phrase. Save it securely!${NC}"
    echo
    read -p "Press Enter to continue..."

    rusk-wallet create

    echo -e "\n${GREEN}${ICON_SUCCESS} Wallet created${NC}"
    read -p "Press Enter to continue..."
}

restore_wallet() {
    echo -e "${YELLOW}${ICON_WALLET} Restoring existing wallet...${NC}"
    echo -e "${ICON_INFO} You will need your 24-word mnemonic phrase${NC}"
    echo
    read -p "Press Enter to continue..."

    rusk-wallet restore

    echo -e "\n${GREEN}${ICON_SUCCESS} Wallet restored${NC}"
    read -p "Press Enter to continue..."
}

profiles_list() {
    echo -e "${YELLOW}${ICON_PROFILE} Wallet Profiles${NC}"
    echo

    rusk-wallet profiles

    read -p "Press Enter to continue..."
}

# ============================================
# BALANCE AND HISTORY FUNCTIONS
# ============================================

check_balance() {
    echo -e "${YELLOW}Checking wallet balance...${NC}"
    echo

    rusk-wallet balance

    read -p "Press Enter to continue..."
}

transaction_history() {
    echo -e "${YELLOW}${ICON_HISTORY} Transaction History${NC}"
    echo

    rusk-wallet history

    read -p "Press Enter to continue..."
}

# ============================================
# TRANSFER FUNCTIONS
# ============================================

transfer_dusk() {
    echo -e "${YELLOW}${ICON_TRANSFER} Transfer DUSK${NC}"
    echo

    echo -e "${CYAN}Current balance:${NC}"
    rusk-wallet balance
    echo

    read -p "Enter recipient address: " recipient
    if [[ -z "$recipient" ]]; then
        echo -e "${RED}Recipient address cannot be empty${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    read -p "Enter amount to send: " amount
    if [[ ! "$amount" =~ ^[0-9]+(\.[0-9]+)?$ ]] || [[ "$amount" == "0" ]]; then
        echo -e "${RED}Invalid amount${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    echo
    echo -e "${YELLOW}Transfer options:${NC}"
    echo "1) Send from default wallet"
    echo "2) Send with custom profile"
    read -p "Select option [1-2]: " transfer_option

    case $transfer_option in
        1)
            echo -e "\n${YELLOW}Sending $amount DUSK to $recipient...${NC}"
            rusk-wallet transfer --rcvr "$recipient" --amt "$amount"
            ;;
        2)
            get_profile_idx
            local profile_idx=$(read_profile_idx)
            echo -e "\n${ICON_PROFILE} Using profile index: $profile_idx"
            echo -e "\n${YELLOW}Sending $amount DUSK from profile $profile_idx to $recipient...${NC}"
            rusk-wallet transfer --profile-idx "$profile_idx" --rcvr "$recipient" --amt "$amount"
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac

    read -p "Press Enter to continue..."
}

# ============================================
# SHIELD/UNSHIELD FUNCTIONS
# ============================================

shield_dusk() {
    echo -e "${YELLOW}${ICON_SHIELD} Shield DUSK (Convert public to shielded)${NC}"
    echo

    echo -e "${CYAN}Current balance:${NC}"
    rusk-wallet balance
    echo

    read -p "Enter amount to shield: " amount
    if [[ ! "$amount" =~ ^[0-9]+(\.[0-9]+)?$ ]] || [[ "$amount" == "0" ]]; then
        echo -e "${RED}Invalid amount${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    echo
    echo -e "${YELLOW}Shielding $amount DUSK...${NC}"
    rusk-wallet shield --amt "$amount"

    read -p "Press Enter to continue..."
}

unshield_dusk() {
    echo -e "${YELLOW}${ICON_SHIELD} Unshield DUSK (Convert shielded to public)${NC}"
    echo

    echo -e "${CYAN}Current balance:${NC}"
    rusk-wallet balance
    echo

    read -p "Enter amount to unshield: " amount
    if [[ ! "$amount" =~ ^[0-9]+(\.[0-9]+)?$ ]] || [[ "$amount" == "0" ]]; then
        echo -e "${RED}Invalid amount${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    echo
    echo -e "${YELLOW}Unshielding $amount DUSK...${NC}"
    rusk-wallet unshield --amt "$amount"

    read -p "Press Enter to continue..."
}

# ============================================
# STAKING FUNCTIONS
# ============================================

stake_dusk() {
    echo -e "${YELLOW}Staking DUSK (minimum 1000)${NC}"

    if ! systemctl is-active --quiet rusk; then
        echo -e "${RED}Node must be running to stake${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    echo -e "\n${CYAN}Current balance:${NC}"
    rusk-wallet balance
    echo

    read -p "Enter amount to stake (minimum 1000): " amount

    if [[ ! "$amount" =~ ^[0-9]+$ ]] || [[ "$amount" -lt 1000 ]]; then
        echo -e "${RED}Invalid amount. Minimum 1000 DUSK${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    echo
    echo -e "${YELLOW}Staking options:${NC}"
    echo "1) Stake from default wallet"
    echo "2) Stake with custom owner address"
    read -p "Select option [1-2]: " stake_option

    case $stake_option in
        1)
            echo -e "\n${YELLOW}Staking $amount DUSK from default wallet...${NC}"
            rusk-wallet stake --amt "$amount"
            ;;
        2)
            echo
            read -p "Enter owner address: " owner_address
            if [[ -z "$owner_address" ]]; then
                echo -e "${RED}Owner address cannot be empty${NC}"
            else
                echo -e "\n${YELLOW}Staking $amount DUSK with owner: $owner_address${NC}"
                rusk-wallet stake --amt "$amount" --owner "$owner_address"
            fi
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac

    read -p "Press Enter to continue..."
}

unstake_dusk() {
    echo -e "${YELLOW}Unstaking DUSK...${NC}"

    echo -e "\n${CYAN}Current stake information:${NC}"
    rusk-wallet stake-info
    echo

    read -p "Are you sure you want to unstake all? (y/N): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo
        echo -e "${YELLOW}Unstaking options:${NC}"
        echo "1) Unstake from default wallet"
        echo "2) Unstake with custom owner address"
        read -p "Select option [1-2]: " unstake_option

        case $unstake_option in
            1)
                echo -e "\n${YELLOW}Unstaking from default wallet...${NC}"
                rusk-wallet unstake
                ;;
            2)
                echo
                read -p "Enter owner address: " owner_address
                if [[ -z "$owner_address" ]]; then
                    echo -e "${RED}Owner address cannot be empty${NC}"
                else
                    echo -e "\n${YELLOW}Unstaking with owner: $owner_address${NC}"
                    rusk-wallet unstake --owner "$owner_address"
                fi
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
    fi

    read -p "Press Enter to continue..."
}

staking_info() {
    echo -e "${YELLOW}Staking Information${NC}"
    echo

    get_profile_idx 0
    local profile_idx=$(read_profile_idx)

    echo -e "\n${ICON_PROFILE} Using profile index: $profile_idx"
    echo

    rusk-wallet stake-info --profile-idx "$profile_idx"

    read -p "Press Enter to continue..."
}

claim_rewards() {
    echo -e "${YELLOW}Claim Stake Rewards${NC}"
    echo

    if ! systemctl is-active --quiet rusk; then
        echo -e "${RED}Node must be running to claim rewards${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    echo -e "${CYAN}Current stake information:${NC}"
    rusk-wallet stake-info
    echo

    read -p "Are you sure you want to claim all rewards? (y/N): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo
        echo -e "${YELLOW}Claiming rewards...${NC}"
        rusk-wallet claim-rewards
    fi

    read -p "Press Enter to continue..."
}

# ============================================
# CONTRACT FUNCTIONS
# ============================================

contract_deploy() {
    echo -e "${YELLOW}${ICON_CONTRACT} Deploy Contract${NC}"
    echo

    read -p "Enter path to contract bytecode file: " bytecode_path
    if [[ ! -f "$bytecode_path" ]]; then
        echo -e "${RED}File not found: $bytecode_path${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    read -p "Enter contract owner address (optional): " owner
    read -p "Enter contract limit (gas limit): " limit

    echo
    echo -e "${YELLOW}Deploying contract...${NC}"

    if [[ -n "$owner" && -n "$limit" ]]; then
        rusk-wallet contract-deploy --bytecode "$bytecode_path" --owner "$owner" --limit "$limit"
    elif [[ -n "$owner" ]]; then
        rusk-wallet contract-deploy --bytecode "$bytecode_path" --owner "$owner"
    elif [[ -n "$limit" ]]; then
        rusk-wallet contract-deploy --bytecode "$bytecode_path" --limit "$limit"
    else
        rusk-wallet contract-deploy --bytecode "$bytecode_path"
    fi

    read -p "Press Enter to continue..."
}

contract_call() {
    echo -e "${YELLOW}${ICON_CONTRACT} Call Contract${NC}"
    echo

    read -p "Enter contract ID: " contract_id
    if [[ -z "$contract_id" ]]; then
        echo -e "${RED}Contract ID cannot be empty${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    read -p "Enter function name: " function_name
    if [[ -z "$function_name" ]]; then
        echo -e "${RED}Function name cannot be empty${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    read -p "Enter function arguments (optional): " args
    read -p "Enter gas limit: " limit

    echo
    echo -e "${YELLOW}Calling contract function $function_name...${NC}"

    if [[ -n "$args" && -n "$limit" ]]; then
        rusk-wallet contract-call --contract "$contract_id" --fn "$function_name" --args "$args" --limit "$limit"
    elif [[ -n "$args" ]]; then
        rusk-wallet contract-call --contract "$contract_id" --fn "$function_name" --args "$args"
    elif [[ -n "$limit" ]]; then
        rusk-wallet contract-call --contract "$contract_id" --fn "$function_name" --limit "$limit"
    else
        rusk-wallet contract-call --contract "$contract_id" --fn "$function_name"
    fi

    read -p "Press Enter to continue..."
}

calculate_contract_id() {
    echo -e "${YELLOW}${ICON_CONTRACT} Calculate Contract ID${NC}"
    echo

    read -p "Enter contract bytecode file path: " bytecode_path
    if [[ ! -f "$bytecode_path" ]]; then
        echo -e "${RED}File not found: $bytecode_path${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    read -p "Enter contract owner address (optional): " owner
    read -p "Enter salt (optional): " salt

    echo
    echo -e "${YELLOW}Calculating contract ID...${NC}"

    if [[ -n "$owner" && -n "$salt" ]]; then
        rusk-wallet calculate-contract-id --bytecode "$bytecode_path" --owner "$owner" --salt "$salt"
    elif [[ -n "$owner" ]]; then
        rusk-wallet calculate-contract-id --bytecode "$bytecode_path" --owner "$owner"
    elif [[ -n "$salt" ]]; then
        rusk-wallet calculate-contract-id --bytecode "$bytecode_path" --salt "$salt"
    else
        rusk-wallet calculate-contract-id --bytecode "$bytecode_path"
    fi

    read -p "Press Enter to continue..."
}

# ============================================
# BLOB FUNCTIONS
# ============================================

send_blob() {
    echo -e "${YELLOW}${ICON_BLOB} Send Blob Transaction${NC}"
    echo

    read -p "Enter blob data (hex string): " blob_data
    if [[ -z "$blob_data" ]]; then
        echo -e "${RED}Blob data cannot be empty${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    echo
    echo -e "${YELLOW}Sending blob transaction...${NC}"
    rusk-wallet blob --data "$blob_data"

    read -p "Press Enter to continue..."
}

# ============================================
# EXPORT KEYS FUNCTION
# ============================================

export_keys() {
    echo -e "${YELLOW}${ICON_KEY} Exporting Consensus Keys${NC}"
    echo "────────────────────────"

    if ! command -v rusk-wallet &> /dev/null; then
        echo -e "${RED}rusk-wallet not found. Please install node first.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi

    get_profile_idx 0
    local profile_idx=$(read_profile_idx)

    echo -e "\n${ICON_PROFILE} Using profile index: $profile_idx"

    # Create conf directory if needed
    sudo mkdir -p "$DUSK_CONF"

    echo -e "Exporting to: ${CYAN}$DUSK_CONF/consensus.keys${NC}"
    echo -e "${YELLOW}You will be prompted for:${NC}"
    echo "  1. Your wallet password"
    echo "  2. A password for the provisioner keys"
    echo
    read -p "Press Enter to continue..."

    rusk-wallet export --profile-idx "$profile_idx" -d "$DUSK_CONF" -n consensus.keys

    if [[ -f "$DUSK_CONF/consensus.keys" ]] && [[ -s "$DUSK_CONF/consensus.keys" ]]; then
        local size=$(stat -c%s "$DUSK_CONF/consensus.keys" 2>/dev/null)
        echo -e "\n${GREEN}${ICON_SUCCESS} Keys exported successfully!${NC}"
        echo -e "File size: $size bytes"

        sudo chmod 600 "$DUSK_CONF/consensus.keys"
        sudo chown $CURRENT_USER:$CURRENT_USER "$DUSK_CONF/consensus.keys"
    else
        echo -e "\n${RED}${ICON_ERROR} Export failed${NC}"
    fi

    read -p "Press Enter to continue..."
}

# ============================================
# SETTINGS FUNCTION
# ============================================

show_settings() {
    echo -e "${YELLOW}${ICON_SETTINGS} Wallet Settings${NC}"
    echo

    rusk-wallet settings

    read -p "Press Enter to continue..."
}

# ============================================
# SET PASSWORD FUNCTION
# ============================================

set_password() {
    echo -e "${YELLOW}${ICON_KEY} Setting Consensus Keys Password${NC}"
    echo "────────────────────────"

    if [[ ! -f "$DUSK_BIN/setup_consensus_pwd.sh" ]]; then
        echo -e "${RED}Password setup script not found${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi

    if [[ ! -f "$DUSK_CONF/consensus.keys" ]]; then
        echo -e "${RED}Consensus keys not found. Please export keys first.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi

    echo -e "Running password setup script..."
    echo -e "${YELLOW}You will be prompted to enter and confirm a password.${NC}"
    echo
    read -p "Press Enter to continue..."

    sudo "$DUSK_BIN/setup_consensus_pwd.sh"

    if [[ -f "$DUSK_CONF/consensus.keys.pass" ]]; then
        echo -e "\n${GREEN}${ICON_SUCCESS} Password set successfully!${NC}"
        sudo chmod 600 "$DUSK_CONF/consensus.keys.pass"
        sudo chown $CURRENT_USER:$CURRENT_USER "$DUSK_CONF/consensus.keys.pass"
    else
        echo -e "\n${RED}${ICON_ERROR} Password setup failed${NC}"
    fi

    read -p "Press Enter to continue..."
}

# ============================================
# NODE CONTROL FUNCTIONS
# ============================================

start_node() {
    echo -e "${YELLOW}Starting node...${NC}"
    sudo systemctl start rusk
    sleep 2

    if systemctl is-active --quiet rusk; then
        sudo systemctl enable rusk
        echo -e "${GREEN}${ICON_SUCCESS} Node started${NC}"
        echo -e "\n${YELLOW}Recent logs:${NC}"
        sudo tail -5 /var/log/rusk.log 2>/dev/null || echo "No logs yet"
    else
        echo -e "${RED}${ICON_ERROR} Failed to start node${NC}"
    fi

    read -p "Press Enter to continue..."
}

stop_node() {
    echo -e "${YELLOW}Stopping node...${NC}"
    sudo systemctl stop rusk
    echo -e "${GREEN}${ICON_SUCCESS} Node stopped${NC}"
    read -p "Press Enter to continue..."
}

restart_node() {
    echo -e "${YELLOW}Restarting node...${NC}"
    sudo systemctl restart rusk
    echo -e "${GREEN}${ICON_SUCCESS} Node restarted${NC}"
    read -p "Press Enter to continue..."
}

# ============================================
# INSTALL NODE FUNCTION
# ============================================

install_node() {
    local network=$1
    echo -e "${YELLOW}${ICON_NODE} Installing Dusk Node for ${GREEN}$network${NC}..."
    echo

    if check_node_installed; then
        echo -e "${RED}Node already installed. Use Clean Installation first.${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    echo -e "Installer: $INSTALLER_URL"
    echo -e "${YELLOW}The installer will prompt you to select network during installation.${NC}"
    echo
    read -p "Press Enter to continue..."

    if [[ "$network" == "testnet" ]]; then
        curl --proto '=https' --tlsv1.2 -sSfL "$INSTALLER_URL" | sudo bash -s -- --network testnet
    else
        curl --proto '=https' --tlsv1.2 -sSfL "$INSTALLER_URL" | sudo bash
    fi

    if [[ $? -eq 0 ]]; then
        echo -e "\n${GREEN}${ICON_SUCCESS} Installation complete${NC}"

        # Save network config
        echo "NETWORK=$network" > "$CONFIG_FILE"
        echo "USER=$CURRENT_USER" >> "$CONFIG_FILE"

        echo -e "\n${CYAN}Next steps:${NC}"
        echo "1. Create/Restore wallet (Wallet Menu → 1 or 2)"
        echo "2. Export consensus keys (Wallet Menu → 17)"
        echo "3. Set password (Wallet Menu → 18)"
        echo "4. Start node (Node Menu → 3)"
        echo "5. Fast-sync node for quicker synchronization (Node Menu → 6 or 7)"
    else
        echo -e "\n${RED}${ICON_ERROR} Installation failed${NC}"
    fi

    read -p "Press Enter to continue..."
}

# ============================================
# MONITORING FUNCTIONS
# ============================================

show_status() {
    echo -e "${CYAN}Node Status${NC}"
    echo "────────────────────────"
    systemctl status rusk --no-pager -l
    read -p "Press Enter to continue..."
}

view_logs() {
    echo -e "${YELLOW}Live logs (Ctrl+C to exit)${NC}"
    sudo journalctl -fu rusk
}

recent_logs() {
    echo -e "${CYAN}Last 50 lines of logs${NC}"
    sudo journalctl -u rusk -n 50 --no-pager
    read -p "Press Enter to continue..."
}

sync_status() {
    echo -e "${CYAN}Sync Status${NC}"
    if command -v ruskquery &> /dev/null; then
        local height=$(ruskquery block-height 2>/dev/null)
        echo -e "Current block height: ${GREEN}$height${NC}"
        echo
        echo -e "Compare with: https://explorer.dusk.network"
    else
        echo -e "ruskquery not available"
    fi
    read -p "Press Enter to continue..."
}

# ============================================
# FIREWALL FUNCTION
# ============================================

configure_firewall() {
    echo -e "${YELLOW}Configuring firewall...${NC}"

    if ! command -v ufw &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y ufw
    fi

    if ! sudo ufw status | grep -q "active"; then
        echo "y" | sudo ufw enable
    fi

    sudo ufw allow 22/tcp comment 'SSH'
    sudo ufw allow 9000/udp comment 'Dusk Kadcast'
    sudo ufw allow 8080/tcp comment 'Dusk HTTP'

    echo -e "${GREEN}${ICON_SUCCESS} Firewall configured${NC}"
    sudo ufw status verbose

    read -p "Press Enter to continue..."
}

# ============================================
# SYSTEM INFO FUNCTION
# ============================================

system_info() {
    echo -e "${CYAN}System Information${NC}"
    echo "────────────────────────"
    echo -e "User: $CURRENT_USER"
    echo -e "OS: $(lsb_release -d 2>/dev/null | cut -f2)"
    echo -e "Kernel: $(uname -r)"
    echo -e "CPU: $(nproc) cores"
    echo -e "RAM: $(free -h | awk '/^Mem:/{print $2}') total"
    echo -e "Disk: $(df -h / | awk 'NR==2{print $4}') free"
    echo
    echo -e "${CYAN}Installation paths:${NC}"
    echo -e "  Dusk: $DUSK_INSTALL_DIR"
    echo -e "  Config: $DUSK_CONF"
    echo -e "  Bin: $DUSK_BIN"
    echo -e "  Wallet: $WALLET_DIR"

    read -p "Press Enter to continue..."
}

# ============================================
# SETUP ASSISTANT
# ============================================

setup_assistant() {
    print_header
    echo -e "${BOLD}${PURPLE}${ICON_ROCKET} SETUP ASSISTANT${NC}"
    echo "──────────────────────────────────────────────────────────"

    # Select network
    echo -e "${CYAN}Select network:${NC}"
    echo "1) Mainnet"
    echo "2) Testnet"
    read -p "Choice [1-2]: " net_choice

    local network="mainnet"
    [[ "$net_choice" == "2" ]] && network="testnet"

    echo -e "\n${GREEN}Selected: $network${NC}"

    # Check and clean existing installation
    if check_node_installed; then
        echo -e "\n${YELLOW}Existing installation detected${NC}"
        read -p "Remove it and install fresh? (y/N): " clean

        if [[ "$clean" =~ ^[Yy]$ ]]; then
            clean_installation
        else
            echo "Setup cancelled"
            read -p "Press Enter to continue..."
            return
        fi
    fi

    # Install node
    echo -e "\n${ICON_STEP} Installing node..."
    install_node "$network"

    # Offer to continue with setup
    echo -e "\n${YELLOW}Continue with wallet setup?${NC}"
    read -p "Proceed? (Y/n): " proceed

    if [[ ! "$proceed" =~ ^[Nn]$ ]]; then
        # Wallet
        echo -e "\n${ICON_STEP} Wallet setup"
        echo "1) Create new wallet"
        echo "2) Restore existing wallet"
        read -p "Choice [1-2]: " wallet_choice

        case $wallet_choice in
            1) create_wallet ;;
            2) restore_wallet ;;
        esac

        # Export keys
        echo -e "\n${ICON_STEP} Exporting keys..."
        export_keys

        # Set password
        echo -e "\n${ICON_STEP} Setting password..."
        set_password

        # Start node
        echo -e "\n${ICON_STEP} Starting node..."
        start_node

        # Ask about fast-sync
        echo -e "\n${YELLOW}Would you like to fast-sync your node?${NC}"
        echo -e "${ICON_INFO} This will download the latest state snapshot for faster synchronization.${NC}"
        read -p "Fast-sync now? (Y/n): " fastsync_choice

        if [[ ! "$fastsync_choice" =~ ^[Nn]$ ]]; then
            fast_sync_node
        fi
    fi

    echo -e "\n${GREEN}${ICON_SUCCESS} Setup complete!${NC}"
    read -p "Press Enter to continue..."
}

# ============================================
# MENUS
# ============================================

main_menu() {
    while true; do
        print_header
        echo -e "${BOLD}${WHITE}MAIN MENU${NC}"
        echo
        echo -e "  ${CYAN}1)${NC} ${ICON_ROCKET} Setup Assistant (Guided Setup)"
        echo -e "  ${CYAN}2)${NC} ${ICON_NODE} Node Management"
        echo -e "  ${CYAN}3)${NC} ${ICON_WALLET} Wallet & Staking"
        echo -e "  ${CYAN}4)${NC} ${ICON_MONITOR} Monitoring"
        echo -e "  ${CYAN}5)${NC} ${ICON_SETTINGS} Configuration"
        echo -e "  ${CYAN}6)${NC} ${ICON_CLEAN} Clean Installation"
        echo -e "  ${CYAN}7)${NC} Exit"
        echo
        read -p "Select option [1-7]: " choice

        case $choice in
            1) setup_assistant ;;
            2) node_menu ;;
            3) wallet_menu ;;
            4) monitor_menu ;;
            5) config_menu ;;
            6) clean_installation ;;
            7) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

node_menu() {
    while true; do
        print_header
        echo -e "${BOLD}${WHITE}${ICON_NODE} NODE MANAGEMENT${NC}"
        echo
        echo -e "  ${CYAN}1)${NC} Install Mainnet"
        echo -e "  ${CYAN}2)${NC} Install Testnet"
        echo -e "  ${CYAN}3)${NC} Start Node"
        echo -e "  ${CYAN}4)${NC} Stop Node"
        echo -e "  ${CYAN}5)${NC} Restart Node"
        echo -e "  ${CYAN}6)${NC} ${ICON_DOWNLOAD} Fast-Sync Node"
        echo -e "  ${CYAN}7)${NC} ${ICON_SYNC} Fast-Sync with Cleanup"
        echo -e "  ${CYAN}8)${NC} List Available States"
        echo -e "  ${CYAN}9)${NC} Back"
        echo
        read -p "Select option [1-9]: " choice

        case $choice in
            1) install_node "mainnet" ;;
            2) install_node "testnet" ;;
            3) start_node ;;
            4) stop_node ;;
            5) restart_node ;;
            6) fast_sync_node ;;
            7) fast_sync_with_cleanup ;;
            8) list_available_states ;;
            9) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

wallet_menu() {
    while true; do
        print_header
        echo -e "${BOLD}${WHITE}${ICON_WALLET} WALLET & STAKING${NC}"
        echo
        echo -e "  ${CYAN}1)${NC} Create New Wallet"
        echo -e "  ${CYAN}2)${NC} Restore Existing Wallet"
        echo -e "  ${CYAN}3)${NC} List Profiles"
        echo -e "  ${CYAN}4)${NC} Check Balance"
        echo -e "  ${CYAN}5)${NC} Transaction History"
        echo -e "  ${CYAN}6)${NC} Transfer DUSK"
        echo -e "  ${CYAN}7)${NC} Shield DUSK"
        echo -e "  ${CYAN}8)${NC} Unshield DUSK"
        echo -e "  ${CYAN}9)${NC} Stake DUSK"
        echo -e "  ${CYAN}10)${NC} Unstake DUSK"
        echo -e "  ${CYAN}11)${NC} Staking Info"
        echo -e "  ${CYAN}12)${NC} Claim Rewards"
        echo -e "  ${CYAN}13)${NC} Deploy Contract"
        echo -e "  ${CYAN}14)${NC} Call Contract"
        echo -e "  ${CYAN}15)${NC} Calculate Contract ID"
        echo -e "  ${CYAN}16)${NC} Send Blob"
        echo -e "  ${CYAN}17)${NC} Export Consensus Keys"
        echo -e "  ${CYAN}18)${NC} Set Keys Password"
        echo -e "  ${CYAN}19)${NC} Show Settings"
        echo -e "  ${CYAN}20)${NC} Back"
        echo
        read -p "Select option [1-20]: " choice

        case $choice in
            1) create_wallet ;;
            2) restore_wallet ;;
            3) profiles_list ;;
            4) check_balance ;;
            5) transaction_history ;;
            6) transfer_dusk ;;
            7) shield_dusk ;;
            8) unshield_dusk ;;
            9) stake_dusk ;;
            10) unstake_dusk ;;
            11) staking_info ;;
            12) claim_rewards ;;
            13) contract_deploy ;;
            14) contract_call ;;
            15) calculate_contract_id ;;
            16) send_blob ;;
            17) export_keys ;;
            18) set_password ;;
            19) show_settings ;;
            20) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

monitor_menu() {
    while true; do
        print_header
        echo -e "${BOLD}${WHITE}${ICON_MONITOR} MONITORING${NC}"
        echo
        echo -e "  ${CYAN}1)${NC} Node Status"
        echo -e "  ${CYAN}2)${NC} Live Logs"
        echo -e "  ${CYAN}3)${NC} Recent Logs"
        echo -e "  ${CYAN}4)${NC} Sync Status"
        echo -e "  ${CYAN}5)${NC} Back"
        echo
        read -p "Select option [1-5]: " choice

        case $choice in
            1) show_status ;;
            2) view_logs ;;
            3) recent_logs ;;
            4) sync_status ;;
            5) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

config_menu() {
    while true; do
        print_header
        echo -e "${BOLD}${WHITE}${ICON_SETTINGS} CONFIGURATION${NC}"
        echo
        echo -e "  ${CYAN}1)${NC} Configure Firewall"
        echo -e "  ${CYAN}2)${NC} System Information"
        echo -e "  ${CYAN}3)${NC} Back"
        echo
        read -p "Select option [1-3]: " choice

        case $choice in
            1) configure_firewall ;;
            2) system_info ;;
            3) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# ============================================
# MAIN
# ============================================

# Print welcome message
clear
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║     Dusk Node Manager - Starting up...                  ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo

# Prerequisites
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}${ICON_INFO} Installing curl...${NC}"
    sudo apt-get update && sudo apt-get install -y curl
fi

echo -e "${BLUE}${ICON_USER} Running as user: ${GREEN}$CURRENT_USER${NC}"
sleep 1

init_directories
main_menu
