#!/bin/bash

set -e  # Exit script if any command fails

# Ensure system package lists are up to date
#sudo apt-get update

# Install required dependencies
sudo apt-get install --assume-yes \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Download the get-mender.sh script and install the Mender client (version 4)
curl -fLsS https://get.mender.io -o get-mender.sh
sudo bash get-mender.sh mender-client4

# Install mender-configure
echo "Installing mender-configure"
sudo apt-get install -y mender-configure

# Set the device_type to fbair in /var/lib/mender/device_type
echo "device_type=fbair" | sudo tee /var/lib/mender/device_type > /dev/null

# Create custom identity script for hardware_id in /etc/mender/identity/mender-device-identity
sudo tee /etc/mender/identity/mender-device-identity > /dev/null << 'EOF'
#!/bin/sh

# Script to collect device identity data for Mender.
# Outputs hardware_id read from a text file.

set -ue  # Exit on error and treat unset variables as errors

HARDWARE_ID_FILE="/home/abel/startup_info/hardware_id.txt"  # File containing the hardware_id

# Check if the hardware_id file exists
if [ -f "$HARDWARE_ID_FILE" ]; then
    hardware_id=$(cat "$HARDWARE_ID_FILE")
    if [ -z "$hardware_id" ]; then
        echo "Error: hardware_id is empty in $HARDWARE_ID_FILE" >&2
        exit 1
    fi
else
    echo "Error: hardware_id file not found at $HARDWARE_ID_FILE" >&2
    exit 1
fi

# Output the hardware_id as the identity
echo "hardware_id=$hardware_id"
EOF

# Make the identity script executable
sudo chmod +x /etc/mender/identity/mender-device-identity

# Set up Mender with JWT and tenant token
JWT_TOKEN="eyJhbGciOiJSUzI1NiIsImtpZCI6MCwidHlwIjoiSldUIn0.eyJqdGkiOiI2ZTA4OWQyMi0wY2EwLTQ2NTYtYTBmYi1hNDVjZGI4MTYyN2IiLCJzdWIiOiI3YzQ5N2YyYy1iYWVhLTQyOTUtOGRmNS0yYTRjNGVhNTI0MDgiLCJpYXQiOjE3MjgzODk3MjYsIm1lbmRlci50ZW5hbnQiOiI2Njg0MzU4MDJiOThmNDUwZDgwYWVlM2QiLCJtZW5kZXIudXNlciI6dHJ1ZSwiaXNzIjoiaG9zdGVkLm1lbmRlci5pbyIsInNjcCI6Im1lbmRlci4qIiwibWVuZGVyLnBsYW4iOiJvcyIsIm1lbmRlci50cmlhbCI6ZmFsc2UsIm1lbmRlci5hZGRvbnMiOlt7Im5hbWUiOiJ0cm91Ymxlc2hvb3QiLCJlbmFibGVkIjp0cnVlfSx7Im5hbWUiOiJjb25maWd1cmUiLCJlbmFibGVkIjpmYWxzZX0seyJuYW1lIjoibW9uaXRvciIsImVuYWJsZWQiOmZhbHNlfV0sIm5iZiI6MTcyODM4OTcyNn0.mrcr1jEqtcsLrQoceJFu8dWds42K04ZVvJxZvKHvPywQhVPBqbEReRE5JJCp2_6cZEIxrr4bvdkyn8Ekhg1Zyx799p6LFoZHzeNM-JQMhwHjOS5QrUq2YoLZWQoVGr08kP0kH1E2vWjQ8STi53KIhXNVV7IXE9IBBkF0bstt7OMoJQ93ppTGpcLFf0FFFaOnIMUs91ouQJYXCoP6TPc-nZDbIqSP-vR-NTfE_0VyH2WJiLCwXrnBTRjUM7CrDRGfs4tJxMWcAzB98yrwzDVydHz3LLECNRRiNypKvTj22dXI6_XqNqKDXMAEHFU33exNiA5gJFTI2aDGPTBfOcJ6_2Zksx0zt6Twq1-gg3HdPNnwUhi53RNu72iVOulCt3xBAz16HNUN42amoqkdz5LOpI9hBoEfKKaLEVze6N9cF_Lgk-niigHJtZisiHB7wda4O2SGw1RABN_jLVnGrMS_DSalfI8CkjX_ILOCj_yG8Bc0nspHIBS045z1VZVXlj6t"
TENANT_TOKEN="-WfKe_xwYlKDDJ-ArrM813P3MEtfWJZvinNDxCYHp_g"

# Use Mender setup to configure the client
wget -O- https://get.mender.io | sudo bash -s -- --demo --jwt-token $JWT_TOKEN --force-mender-client4 -- --quiet --device-type "fbair" --tenant-token $TENANT_TOKEN --retry-poll 300 --update-poll 1800 --inventory-poll 28800 --server-url https://hosted.mender.io --server-cert=""

# Restart the Mender service
sudo systemctl restart mender-updated

echo "Mender client installation complete."
