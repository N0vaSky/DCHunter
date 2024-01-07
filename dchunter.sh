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

# Function to validate CIDR notation or single IP address
validate_input() {
    local input="$1"
    local cidr_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$"
    local ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

    if [[ ! $input =~ $cidr_regex && ! $input =~ $ip_regex ]]; then
        # Verbose comment for invalid input
        echo -e "${RED}Invalid input. Please enter a valid CIDR range (e.g., 10.0.0.0/24) or a single IP address.${RESET}"
        exit 1
    fi
}

read -p "Enter the CIDR subnet or a single IP address: " input

# Validate input
validate_input "$input"

# Task 1: Scan for potential Domain Controllers
echo -e "\n${CYAN}Task 1: Scanning for potential Domain Controllers in the subnet...${RESET}"
nmap_command="sudo nmap -p 88,389,636 --open --script nbstat -oG - $input"
echo -e "${RED}Running: $nmap_command${RESET}"
nmap_output=$(eval "$nmap_command")

# Display Task 1 output
echo -e "\n${CYAN}=== Task 1 Output ===${RESET}\n"
while IFS= read -r line; do
    if [[ "$line" =~ "Host:" || "$line" =~ "Ports:" ]]; then
        # Highlight important lines in red
        echo -e "${RED}$line${RESET}"
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
