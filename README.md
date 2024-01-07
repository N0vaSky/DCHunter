# DCHunter v1.0

This script helps identify potential Domain Controllers in a given CIDR subnet or a single IP address. It uses Nmap to scan for common Domain Controller ports and performs NetBIOS name lookup on discovered hosts.

## Prerequisites

Ensure that the following tools are installed on your system:

- [Nmap](https://nmap.org/)
- [nmblookup](https://linux.die.net/man/1/nmblookup)

Install any missing tools before running the script.

## Usage

1. Clone the repository:

   ```bash
   git clone https://github.com/JoshTStrickland/dchunter.git
   cd dchunter
   sudo ./dchunter.sh

- Happy hacking :)

