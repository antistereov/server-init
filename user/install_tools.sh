#!/bin/bash
set -e

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

# Set your git credentials
export GIT_NAME=""
export GIT_EMAIL=""

# Validate input
if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
    error "GIT_NAME or GIT_EMAIL not set"
fi

######################## INSTALL HOMEBREW #############################

if command -v brew >/dev/null 2>&1; then
    success "Homebrew is already installed."
else
    info "Installing Homebrew..."

    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bash_profile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

    success "Homebrew installation complete."
fi

brew --version

###################### INSTALL USEFUL TOOLS #############################

info "Installing Fish, zoxide, and btop..."
brew install fish zoxide btop
success "Tools installed."

# Add fish to accepted shells
if ! grep -q "$(which fish)" /etc/shells; then
    info "Adding fish to /etc/shells..."
    echo "$(which fish)" | sudo tee -a /etc/shells
fi

# Set fish as default shell
info "Setting fish as default shell..."
chsh -s "$(which fish)"
success "Fish set as default shell."

# Add Homebrew to fish path
info "Adding Homebrew to fish PATH..."
fish -c 'fish_add_path /home/linuxbrew/.linuxbrew/bin'
success "Homebrew added to fish PATH."

# Ensure fish config dir
mkdir -p ~/.config/fish

# Add zoxide init to config if missing
if ! grep -q "zoxide init fish" ~/.config/fish/config.fish 2>/dev/null; then
    echo 'zoxide init fish | source' >> ~/.config/fish/config.fish
    success "Configured zoxide in fish."
else
    warn "zoxide already configured in fish."
fi

############################ CONFIGURE GIT ###############################

info "Configuring Git global user..."
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
success "Git configured."

success "✅ Setup complete. Restart your terminal for changes to take effect."
