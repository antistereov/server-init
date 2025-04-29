#!/bin/bash
set -euo pipefail

export USERNAME=""
export PASSWORD=""
export SSH_PORT=2222
export SSHD_CONFIG_FILE="/etc/ssh/sshd_config"

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m" # No Color

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    error "Error: USERNAME or PASSWORD is not set"
fi

######################## CHANGE SSH CONFIG #############################

# Back up the config

info "Backing up the sshd config..."
cp "$SSHD_CONFIG_FILE" "${SSHD_CONFIG_FILE}.bak"

# Change port

info "Changing SSH Port to $SSH_PORT"
if grep -q "^#\?Port " "$SSHD_CONFIG_FILE"; then
    sudo sed -i "s/^#\?Port .*/Port $SSH_PORT/" "SSHD_CONFIG_FILE"
else
    echo "Port $SSH_PORT" | sudo tee -a "$SSHD_CONFIG_FILE"
fi
success "SSH port changed to $SSH_PORT."

# Disable password authentication

info "Disabling password authentication in SSH..."
if grep -q "^#\?PasswordAuthentication " "$SSHD_CONFIG_FILE"; then
    sudo sed -i "s/^#\?PasswordAuthentication .*/PasswordAuthentication no/" "SSHD_CONFIG_FILE"
else
    echo "PasswordAuthentication $SSH_PORT" | sudo tee -a "$SSHD_CONFIG_FILE"
fi
success "Password authentication disabled."

# Restart SSH

info "Restarting daemon..."
sudo systemctl restart sshd

######################## CREATE ADMIN ACCOUNT ##########################

info "Creating admin account $USERNAME..."
useradd -m "$USERNAME"

echo "$USERNAME:$PASSWORD" | sudo chpasswd
success "Admin account created."

info "Authorizing known SSH keys for $USERNAME..."
mkdir /home/$USERNAME/.ssh
cp /root/.ssh/authorized_keys /home/$USERNAME/.ssh
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
success "Keys authorized."

success "✅ Setup complete. Reboot the system and log in as $USERNAME."