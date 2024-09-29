#!/bin/bash

# Installation framework for lightshowPi

# Installation directory
INSTALL_DIR="$( cd $(dirname $0) ; pwd -P )"
BUILD_DIR=${INSTALL_DIR}/build_dir

# Package manager installation command
INSTALL_COMMAND="apt-get install -q=2 -y"

# Python dependencies to be installed
PYTHON_DEPS=(numpy beautifulsoup4 mutagen simplejson twython emoji \
             spidev BiblioPixel pillow pyserial pyalsaaudio)

# System packages to be installed
SYSTEM_DEPS=(python3-pip python3-dev curl faad flac gcc git lame mpg123 make \
             python3-numpy python3-setuptools unzip vorbis-tools subversion \
             cython3 pianobar libjpeg-dev libtiff-dev libatlas-base-dev \
             pigpio)  # Replaced wiringPi with pigpio

# Set up file-based logging
exec 1> >(tee install.log)

# Root check
if [ "$EUID" -ne 0 ]; then
    echo 'Install script requires root privileges!'
    if [ -x /usr/bin/sudo ]; then
        echo 'Switching now, enter the password for "'$USER'", if prompted.'
        sudo su -c "$0 $*"
    else
        echo 'Switching now, enter the password for "root"!'
        su root -c "$0 $*"
    fi
    exit $?
fi

# Wrapper for informational logging
log() {
    echo -ne "\e[1;34mlightshowpi \e[m" >&2
    echo -e "[`date`] $@"
}

# Checks the return value of the last command to run
verify() {
    if [ $? -ne 0 ]; then
        echo "Encountered a fatal error: $@"
        exit 1
    fi
}

# Miscellaneous checks
log "Removing outdated Python packages..."
apt-get -y remove python-simplejson
apt-get -y remove python-serial
apt-get -y remove python-spidev

# Disable GL driver
log "Disabling GL driver..."
raspi-config nonint do_gldriver G3

# Install ffmpeg
log "Installing ffmpeg..."
$INSTALL_COMMAND ffmpeg
verify "Installation of ffmpeg failed"

# Prepare the build environment
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR && cd $BUILD_DIR

# Install system dependencies
log "Preparing to install ${#SYSTEM_DEPS[@]} system packages..."
for dep in "${SYSTEM_DEPS[@]}"; do
    log "Installing $dep..."
    $INSTALL_COMMAND "$dep"
    verify "Installation of $dep failed"
done

# Install decoder
log "Installing decoder..."
pip3 install --upgrade git+https://broken2048@bitbucket.org/broken2048/decoder-v3.py.git
verify "Installation of decoder failed"

# Install Python dependencies
log "Preparing to install ${#PYTHON_DEPS[@]} Python packages..."
for dep in "${PYTHON_DEPS[@]}"; do
    log "Installing $dep via pip..."
    if [ "$dep" == "numpy" ]; then
        echo -e "\e[1;33mWARNING:\e[m numpy installation may take up to 30 minutes"; 
    fi
    /usr/bin/yes | pip3 install --upgrade "$dep"
    verify "Installation of Python package $dep failed"
done

# Additional installations
log "Installing rpi-audio-levels..."
pip3 install git+https://broken2048@bitbucket.org/broken2048/rpi-audio-levels.git
verify "Installation of rpi-audio-levels failed"

log "Installing pygooglevoice..."
pip3 install --upgrade git+https://github.com/pettazz/pygooglevoice.git
verify "Installation of pygooglevoice failed"

log "Installing wiringpipy..."
pip3 install --upgrade git+https://broken2048@bitbucket.org/broken2048/wiringpipy.git
verify "Installation of wiringpipy failed"

# Optionally add a line to /etc/sudoers
if [ -f /etc/sudoers ]; then
    KEEP_EN='Defaults             env_keep="SYNCHRONIZED_LIGHTS_HOME"'
    grep -q "$KEEP_EN" /etc/sudoers
    if [ $? -ne 0 ]; then
        echo "$KEEP_EN" >> /etc/sudoers
    fi
fi

# Set up environment variables
cat <<EOF >/etc/profile.d/lightshowpi.sh
# Lightshow Pi Home
export SYNCHRONIZED_LIGHTS_HOME=${INSTALL_DIR}
# Add Lightshow Pi bin directory to path
export PATH=\$PATH:${INSTALL_DIR}/bin
EOF

# Clean up after ourselves
cd ${INSTALL_DIR} && rm -rf ${BUILD_DIR}

# Print some instructions to the user
cat <<EOF


All done! Reboot your Raspberry Pi before running lightshowPi.
Run the following command to test your installation and hardware setup:

    sudo python $INSTALL_DIR/py/hardware_controller.py --state=flash

EOF

exit 0
