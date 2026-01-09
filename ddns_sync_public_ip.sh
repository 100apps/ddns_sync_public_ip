#!/bin/bash

# DDNS Public IP Sync Script
# Purpose: Automatically update DNS records when public IP changes (for PPPoE networks)

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/ddns_config.conf"
LOG_FILE="${SCRIPT_DIR}/ddns_sync.log"
LAST_IP_FILE="${SCRIPT_DIR}/.last_ip"

# Default values (can be overridden by config file)
IP_METHOD="curl"  # Options: curl, ifconfig
IP_CHECK_URL="https://api.ipify.org"  # Used when IP_METHOD=curl
IFCONFIG_INTERFACE=""  # Used when IP_METHOD=ifconfig (e.g., ppp0)
DNS_API_URL=""
DNS_API_TOKEN=""
DNS_RECORD_ID=""
DNS_DOMAIN=""

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Get public IP address
get_public_ip() {
    local ip=""
    
    if [ "$IP_METHOD" = "curl" ]; then
        # Method 1: Using curl to query external service
        ip=$(curl -s --max-time 10 "$IP_CHECK_URL" 2>/dev/null)
        if [ $? -ne 0 ] || [ -z "$ip" ]; then
            # Fallback to another service
            ip=$(curl -s --max-time 10 "https://ifconfig.me" 2>/dev/null)
        fi
    elif [ "$IP_METHOD" = "ifconfig" ]; then
        # Method 2: Using ifconfig to get IP from specific interface
        if [ -n "$IFCONFIG_INTERFACE" ]; then
            ip=$(ifconfig "$IFCONFIG_INTERFACE" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
        else
            log "ERROR: IFCONFIG_INTERFACE not specified in config"
            return 1
        fi
    else
        log "ERROR: Invalid IP_METHOD: $IP_METHOD"
        return 1
    fi
    
    # Validate IP format
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$ip"
        return 0
    else
        log "ERROR: Failed to get valid IP address"
        return 1
    fi
}

# Get last recorded IP
get_last_ip() {
    if [ -f "$LAST_IP_FILE" ]; then
        cat "$LAST_IP_FILE"
    else
        echo ""
    fi
}

# Save current IP to file
save_last_ip() {
    echo "$1" > "$LAST_IP_FILE"
}

# Update DNS record via API
update_dns() {
    local new_ip="$1"
    
    # Check if DNS configuration is set
    if [ -z "$DNS_API_URL" ]; then
        log "WARNING: DNS_API_URL not configured. Skipping DNS update."
        log "INFO: Please configure DNS API settings in $CONFIG_FILE"
        return 1
    fi
    
    log "INFO: Updating DNS record for $DNS_DOMAIN to $new_ip"
    
    # Example API call - modify according to your DNS provider
    # This is a generic example, you need to customize it for your DNS provider
    local response
    if [ -n "$DNS_API_TOKEN" ]; then
        response=$(curl -s -X POST "$DNS_API_URL" \
            -H "Authorization: Bearer $DNS_API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"ip\":\"$new_ip\",\"domain\":\"$DNS_DOMAIN\",\"record_id\":\"$DNS_RECORD_ID\"}" \
            2>&1)
    else
        response=$(curl -s -X POST "$DNS_API_URL" \
            -H "Content-Type: application/json" \
            -d "{\"ip\":\"$new_ip\",\"domain\":\"$DNS_DOMAIN\",\"record_id\":\"$DNS_RECORD_ID\"}" \
            2>&1)
    fi
    
    # Check if update was successful
    # Note: You may need to customize this check based on your DNS API response
    if [ $? -eq 0 ]; then
        log "INFO: DNS update response: $response"
        log "SUCCESS: DNS record updated successfully"
        return 0
    else
        log "ERROR: Failed to update DNS record: $response"
        return 1
    fi
}

# Check and setup crontab
setup_crontab() {
    local script_path="$SCRIPT_DIR/ddns_sync_public_ip.sh"
    local cron_command="* * * * * $script_path"
    
    # Check if crontab entry already exists
    if crontab -l 2>/dev/null | grep -q "$script_path"; then
        log "INFO: Crontab entry already exists"
        return 0
    fi
    
    log "INFO: Adding crontab entry to run every minute"
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "$cron_command") | crontab -
    
    if [ $? -eq 0 ]; then
        log "SUCCESS: Crontab entry added successfully"
        return 0
    else
        log "ERROR: Failed to add crontab entry"
        return 1
    fi
}

# Main function
main() {
    log "INFO: Starting DDNS sync check"
    
    # Step 0: Setup crontab if not exists
    if [ "$1" = "--setup-cron" ]; then
        setup_crontab
        exit $?
    fi
    
    # Step 1: Get current public IP
    current_ip=$(get_public_ip)
    if [ $? -ne 0 ] || [ -z "$current_ip" ]; then
        log "ERROR: Failed to retrieve public IP"
        exit 1
    fi
    
    log "INFO: Current public IP: $current_ip"
    
    # Step 2: Check last recorded IP
    last_ip=$(get_last_ip)
    
    if [ -n "$last_ip" ] && [ "$current_ip" = "$last_ip" ]; then
        log "INFO: IP has not changed (still $current_ip). No action needed."
        exit 0
    fi
    
    log "INFO: IP has changed from [$last_ip] to [$current_ip]"
    
    # Step 3: Update DNS record
    if update_dns "$current_ip"; then
        # Save the new IP only if update was successful
        save_last_ip "$current_ip"
        log "SUCCESS: IP change processed successfully"
    else
        log "ERROR: DNS update failed, will retry on next run"
        exit 1
    fi
}

# Run main function
main "$@"
