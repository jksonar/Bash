#!/bin/bash

# Script to setup local repository for Red Hat 9
set -e  # Exit immediately if a command exits with a non-zero status

REPO_DIR="/var/repo"
DEVICE="/dev/sr0"
REPO_FILE="/etc/yum.repos.d/rhel9-local.repo"
GPG_KEY="/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting repository setup."

# Ensure the device exists before proceeding
if [ ! -b $DEVICE ]; then
    log "Error: $DEVICE not found. Please insert the RHEL installation media."
    exit 1
fi

# Create repo directory if it does not exist
if [ ! -d $REPO_DIR ]; then
    log "$REPO_DIR not found. Creating..."
    mkdir -p $REPO_DIR
fi

# Mount the installation media
if mountpoint -q $REPO_DIR; then
    log "$REPO_DIR is already mounted."
else
    log "Mounting $DEVICE to $REPO_DIR."
    mount $DEVICE $REPO_DIR || {
        log "Failed to mount $DEVICE."
        exit 1
    }
fi

# Create repository file
log "Creating YUM repository configuration at $REPO_FILE."
cat > $REPO_FILE << EOF
[Local-BaseOS]
name=Red Hat Enterprise Linux 9 - BaseOS
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file://$REPO_DIR/BaseOS/
gpgkey=file://$GPG_KEY

[Local-AppStream]
name=Red Hat Enterprise Linux 9 - AppStream
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file://$REPO_DIR/AppStream/
gpgkey=file://$GPG_KEY
EOF

log "Repository setup completed successfully."
