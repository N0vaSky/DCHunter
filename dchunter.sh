#!/bin/bash

# Define color codes
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
RESET='\e[0m'

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if required software is installed
required_tools=("nmap" "nmblookup")
missing_tools=()

for tool in "${required_tools[@]}"; do
    if ! command_exists "$tool"; then
        missing_tools+=("$tool")
    fi
done

if [[ "${#missing_tools[@]}" -gt 0 ]]; then
    # Verbose comment for missing tools
    echo -e "${RED}Required tools are missing: ${missing_tools[*]}${RESET}"
    echo "Please install the missing tools and rerun the script with elevated privileges (sudo)."
    exit 1
fi

# Function to validate CIDR notation
validate_cidr() {
    local cidr="$1"
    local regex="^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$"
    
    if [[ ! $cidr =~ $regex ]]; then
        # Verbose comment for invalid CIDR notation
        echo -e "${RED}Invalid CIDR notation. Please enter a valid CIDR range (e.g., 10.0.0.0/24).${RESET}"
        exit 1
    fi
}

read -p "Enter the CIDR subnet or a single IP (e.g., 10.0.0.0/24 or 10.0.0.2): " subnet

# Validate CIDR notation
validate_cidr "$subnet"

# Task 1: Scan for potential Domain Controllers
echo -e "\n${CYAN}Task 1: Scanning for potential Domain Controllers in the subnet...${RESET}"
nmap_command="sudo nmap -p 88,389,636 --open --script nbstat -oG - $subnet"
echo -e "${YELLOW}Running: $nmap_command${RESET}"
nmap_output=$(eval "$nmap_command")

# Display Task 1 output
echo -e "\n${CYAN}=== Task 1 Output ===${RESET}\n"
while IFS= read -r line; do
    if [[ "$line" =~ "Host:" || "$line" =~ "Ports:" ]]; then
        # Highlight important lines in yellow
        echo -e "${YELLOW}$line${RESET}"
    else
        echo -e "$line"
    fi
done <<< "$nmap_output"

# Task 2: Perform NetBIOS name lookup
echo -e "\n${CYAN}Task 2: Performing NetBIOS name lookup...${RESET}"
unique_ips=()
while IFS= read -r line; do
    if [[ "$line" =~ "Host:" ]]; then
        ip=$(echo "$line" | awk '{print $2}')
        
        # Check if the IP has already been processed
        if [[ ! " ${unique_ips[@]} " =~ " $ip " ]]; then
            unique_ips+=("$ip")

            netbios_name_command="nmblookup -A $ip"
            echo -e "${YELLOW}Running: $netbios_name_command${RESET}"
            netbios_name=$(eval "$netbios_name_command" | grep "<00>" | awk '{print $1}')
            
            # Verbose comment for failure in NetBIOS lookup
            if [ -z "$netbios_name" ]; then
                echo -e "${RED}Failed to retrieve NetBIOS Name for $ip.${RESET}"
            else
                echo -e "${CYAN}NetBIOS Name for ${GREEN}$ip${CYAN}: ${GREEN}$netbios_name${RESET}"
            fi
        fi
    fi
done <<< "$nmap_output"

# Verbose comment for script completion
echo -e "\n${GREEN}Script completed.${RESET}"

# Move the script to /usr/local/bin and make it executable
sudo mv "$0" /usr/local/bin/dchunter
sudo chmod +x /usr/local/bin/dchunter
