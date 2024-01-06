#!/bin/bash

echo -e "\e[1;31m
    ___  ___                      _            
   /   \/ __\   /\  /\_   _ _ __ | |_ ___ _ __ 
  / /\ / /     / /_/ / | | | '_ \| __/ _ \ '__|
 / /_// /___  / __  /| |_| | | | | ||  __/ |    v1.0
/___,'\____/  \/ /_/  \__,_|_| |_|\__\___|_|   
                                               
\e[0m"

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if required software is installed
if ! command_exists "enum4linux"; then
    echo "enum4linux is not installed. Installing..."
    sudo apt-get install -y enum4linux
fi

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local regex="^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$"
    
    if [[ ! $cidr =~ $regex ]]; then
        echo "Invalid CIDR notation. Please enter a valid CIDR range (e.g., 10.0.0.0/24)."
        exit 1
    fi
}

# Display help menu
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo -e "Usage: $0 [OPTIONS]"
    echo -e "Identify potential Domain Controllers in a subnet using enum4linux."
    echo -e "\nOptions:"
    echo -e "  -h, --help\tDisplay this help menu"
    exit 0
fi

read -p "Enter the CIDR subnet (e.g., 10.0.0.0/24): " subnet

# Validate CIDR notation
validate_cidr "$subnet"

trap 'echo -e "\nScript terminated by user." && exit 1' INT

echo "Identifying potential Domain Controllers in the subnet..."
for ip in {1..254}; do
    target_ip="${subnet%.*}.$ip"
    
    # Check if the host is reachable with a timeout of 1 second
    if ping -c 1 -W 1 "$target_ip" >/dev/null; then
        echo -e "\nScanning..."
        
        # Spinning Scanning animation
        spinner="/|\\-/|\\-"
        count=0
        while : ; do
            echo -n "${spinner:$count:1}"
            sleep 0.1
            count=$(( (count + 1) % 8 ))
            echo -ne "\b"
        done &
        spinner_pid=$!
        
        # Run enum4linux with additional options
        enum_output=$(enum4linux -a -U -v -d "$target_ip" 2>/dev/null)
        
        # Stop the spinner
        kill $spinner_pid > /dev/null 2>&1
        wait $spinner_pid > /dev/null 2>&1
        echo -e "] Done!"
        
        # Check if the output contains domain controller information
        if echo "$enum_output" | grep -qi "domain controller"; then
            # Extract domain controller name
            dc_name=$(echo "$enum_output" | grep -oP '^\s*Domain\s*:\s*\K.{1,50}' | tr -d '\r')
            
            echo -e "\nFound Domain Controller! :D"
            echo "Domain Controller IP: $target_ip"
            
            # Pause and ask for key press before showing Domain Controller information
            read -n 1 -s -r -p "Press any key to show Domain Controller information..."
            
            # Display the output of enum4linux
            echo -e "\n=== Domain Controller Information ===\n"
            sleep 1
            echo "$enum_output"
            
            echo "---------------------------------------------"
        else
            echo "IP $target_ip is responsive but not a Domain Controller."
            echo "---------------------------------------------"
        fi
    fi
done

echo "Script completed."
