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
apt-get install -y pigpio python3-pigpio python3-pip ffmpeg libfftw3-dev python3-venv libasound2-dev git lame

# Enable pigpio at startup
systemctl enable pigpiod
systemctl start pigpiod

# Create a Python virtual environment
echo "Creating a Python virtual environment..."
python3 -m venv /opt/lightshowpi_venv
source /opt/lightshowpi_venv/bin/activate

# Install Python packages within the virtual environment
echo "Installing Python dependencies within the virtual environment..."
pip install wheel numpy pyfftw Pillow beautifulsoup4 mutagen pyalsaaudio
pip install Cython  # Install Cython for compiling Python code to C
pip install bibliopixel  # Install BiblioPixel for LED animation
pip install pyserial  # Install pyserial for serial communication

# Installing decoder from a Git repository
pip install --upgrade git+https://broken2048@bitbucket.org/broken2048/decoder-v3.py.git

# Clone the GitHub repository
echo "Cloning the rpi-audio-levels repository..."
git clone https://github.com/shineonwcs/rpi-audio-levels.git /opt/rpi-audio-levels

# Change to the repository directory
cd /opt/rpi-audio-levels

# Install the Python package from the repository
echo "Installing rpi-audio-levels Python package..."
pip install .

# Return to the original directory
cd -

# Deactivate the virtual environment
deactivate

echo "Setting up environment variables..."
export SYNCHRONIZED_LIGHTS_HOME="/home/pi/lightshowpi"
echo 'export SYNCHRONIZED_LIGHTS_HOME="/home/pi/lightshowpi"' >> ~/.bashrc

echo "Installation completed successfully."
echo "Please check the above messages to ensure everything was installed properly."
