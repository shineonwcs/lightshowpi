#!/bin/bash

# Setup logging and check root privileges
echo "Starting installation..."
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update and install system dependencies
echo "Updating package list and installing system packages..."
apt-get update
apt-get install -y pigpio python3-pigpio python3-pip ffmpeg libfftw3-dev python3-venv

# Enable pigpio at startup
systemctl enable pigpiod
systemctl start pigpiod

# Create a Python virtual environment
echo "Creating a Python virtual environment..."
python3 -m venv /opt/lightshowpi_venv
source /opt/lightshowpi_venv/bin/activate

# Install Python packages within the virtual environment
echo "Installing Python dependencies within the virtual environment..."
pip install numpy pyfftw Pillow beautifulsoup4 mutagen

# Deactivate the virtual environment
deactivate

echo "Installation completed successfully."
echo "Please check the above messages to ensure everything was installed properly."