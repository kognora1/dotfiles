#!/bin/bash
# =============================================================================
# Nora's dotfiles restore script — Fedora 44 Minimal + NVIDIA (GTX 1050 Ti)
# Run this ONCE after first login on a fresh F44 install
# Usage: bash restore.sh
# =============================================================================

set -e

DOTFILES="/mnt/files/dotfiles-backup"
BOLD="\e[1m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

info()    { echo -e "${BOLD}${GREEN}[INFO]${RESET} $1"; }
warn()    { echo -e "${BOLD}${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${BOLD}${RED}[ERROR]${RESET} $1"; exit 1; }
section() { echo -e "\n${BOLD}========================================\n  $1\n========================================${RESET}"; }

# =============================================================================
section "0. Pre-flight checks"
# =============================================================================

if [ ! -d "$DOTFILES" ]; then
    error "$DOTFILES not found. Is the /mnt/files HDD mounted?"
fi
info "Backup found at $DOTFILES"

if [ "$EUID" -eq 0 ]; then
    error "Do not run this script as root. Run as your normal user."
fi
info "Running as $(whoami) — good."

# =============================================================================
section "1. Add repositories"
# =============================================================================

info "Adding RPM Fusion (free)..."
sudo dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

info "Adding RPM Fusion (nonfree)..."
sudo dnf install -y \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

info "Adding solopasha/hyprland COPR..."
sudo dnf copr enable -y solopasha/hyprland

info "Adding lihaohong/yazi COPR (needed for some dependencies)..."
sudo dnf copr enable -y lihaohong/yazi

info "Adding LibreWolf repo..."
curl -fsSL https://rpm.librewolf.net/librewolf-repo.repo | sudo tee /etc/yum.repos.d/librewolf.repo

info "Adding ProtonVPN repo..."
sudo dnf install -y https://repo.protonvpn.com/fedora-$(rpm -E %fedora)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.3-1.noarch.rpm

info "Refreshing repos..."
sudo dnf makecache

# =============================================================================
section "2. NVIDIA driver (GTX 1050 Ti — GP107)"
# =============================================================================

info "Installing NVIDIA proprietary driver..."
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

info "Waiting for kernel module to build (this can take 2-5 minutes)..."
sudo akmods --force

info "Verifying NVIDIA module..."
modinfo -F version nvidia || warn "Module not ready yet — it may finish after reboot."

info "Setting NVIDIA kernel parameters..."
sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1 nvidia-drm.fbdev=1"

# =============================================================================
section "3. Install packages"
# =============================================================================

info "Installing all packages..."
sudo dnf install -y \
    `# Shell & terminal` \
    zsh foot eza bat fastfetch ripgrep htop bc rsync aria2 yt-dlp jq inotify-tools \
    \
    `# Wayland / Hyprland stack` \
    hyprland hyprlock hyprpaper hyprpicker hyprcursor hyprland-uwsm uwsm \
    waybar fuzzel mako slurp grim wl-clipboard \
    xdg-desktop-portal-hyprland swayimg wlr-randr brightnessctl \
    \
    `# Audio` \
    pipewire pipewire-pulseaudio wireplumber pavucontrol playerctl \
    \
    `# Theming` \
    kvantum qt6ct nwg-look nwg-panel \
    papirus-icon-theme papirus-icon-theme-light papirus-icon-theme-dark \
    \
    `# Apps` \
    firefox librewolf mpv qbittorrent pcmanfm \
    zathura zathura-pdf-poppler \
    \
    `# KDE/LXQt (polkit agent + Qt support)` \
    lxqt-policykit kde-cli-tools kdotool \
    \
    `# Media codecs` \
    ffmpeg mediainfo \
    \
    `# Fonts (system-level)` \
    fontawesome-6-brands-fonts fontawesome-6-free-fonts \
    \
    `# Dev tools` \
    git neovim gcc make cargo rust tree-sitter-cli pipx \
    \
    `# Misc utils` \
    wget2-wget xsel xdg-utils xdg-user-dirs

# =============================================================================
section "4. ProtonVPN"
# =============================================================================

info "Installing ProtonVPN..."
sudo dnf install -y proton-vpn-gnome-desktop

# =============================================================================
section "5. Flatpaks"
# =============================================================================

info "Installing Flatpaks..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub io.github.localsend.localsend_app

# =============================================================================
section "6. pipx tools"
# =============================================================================

info "Installing hyprshade via pipx..."
pipx install hyprshade

# =============================================================================
section "7. Set zsh as default shell"
# =============================================================================

info "Setting zsh as default shell..."
chsh -s "$(which zsh)"

# =============================================================================
section "8. Restore dotfiles"
# =============================================================================

info "Restoring ~/.config..."
cp -r "$DOTFILES/config/"* ~/.config/

info "Restoring ~/.local/bin (scripts)..."
mkdir -p ~/.local/bin
cp -r "$DOTFILES/local/bin/"* ~/.local/bin/
chmod +x ~/.local/bin/*.sh
chmod +x ~/.local/bin/kb-status

info "Restoring fonts..."
mkdir -p ~/.local/share/fonts
cp -r "$DOTFILES/local/share/fonts/"* ~/.local/share/fonts/
fc-cache -fv

info "Restoring themes..."
mkdir -p ~/.local/share/themes
cp -r "$DOTFILES/local/share/themes/"* ~/.local/share/themes/

info "Restoring local icons..."
mkdir -p ~/.local/share/icons
cp -r "$DOTFILES/local/share/icons/"* ~/.local/share/icons/

info "Restoring ~/.icons (cursors + papirus-folders)..."
cp -r "$DOTFILES/home/.icons" ~/

info "Restoring home dotfiles..."
cp "$DOTFILES/home/.bashrc"       ~/
cp "$DOTFILES/home/.bash_profile" ~/
cp "$DOTFILES/home/.gitconfig"    ~/
cp "$DOTFILES/home/.gtk-bookmarks" ~/

info "Restoring dconf settings (GTK theme, cursor, icons)..."
dconf load / < "$DOTFILES/home/dconf-backup.ini"

# =============================================================================
section "9. Create symlinks"
# =============================================================================

info "Creating ~/.zshrc symlink..."
ln -sf ~/.config/zsh/.zshrc ~/.zshrc

info "Creating ~/.zprofile symlink..."
ln -sf ~/.config/shell/profile ~/.zprofile

# =============================================================================
section "10. Restore XDG user dirs symlinks"
# =============================================================================

info "Creating XDG directory symlinks to /mnt/files..."
ln -sf /mnt/files/Documents ~/Documents
ln -sf /mnt/files/Music     ~/Music
ln -sf /mnt/files/Pictures  ~/Pictures
ln -sf /mnt/files/Roms      ~/Roms
ln -sf /mnt/files/Videos    ~/Videos

# =============================================================================
section "11. Update hyprland.conf for NVIDIA"
# =============================================================================

info "Switching hyprland.conf from iGPU to NVIDIA..."
HYPRCONF="$HOME/.config/hypr/hyprland.conf"

# Comment out the iGPU line
sed -i 's|^env = WLR_DRM_DEVICES,/dev/dri/card1|#env = WLR_DRM_DEVICES,/dev/dri/card1|' "$HYPRCONF"

# Uncomment the NVIDIA env vars
sed -i 's|^#env = LIBVA_DRIVER_NAME,nvidia|env = LIBVA_DRIVER_NAME,nvidia|' "$HYPRCONF"
sed -i 's|^#env = XDG_SESSION_TYPE,wayland|env = XDG_SESSION_TYPE,wayland|' "$HYPRCONF"
sed -i 's|^#env = GBM_BACKEND,nvidia-drm|env = GBM_BACKEND,nvidia-drm|' "$HYPRCONF"
sed -i 's|^#env = __GLX_VENDOR_LIBRARY_NAME,nvidia|env = __GLX_VENDOR_LIBRARY_NAME,nvidia|' "$HYPRCONF"
sed -i 's|^#env = NVD_BACKEND,direct|env = NVD_BACKEND,direct|' "$HYPRCONF"

# WLR_NO_HARDWARE_CURSORS is already handled by cursor { no_hardware_cursors = true }
# so we leave that block as-is

info "hyprland.conf updated for NVIDIA."

# =============================================================================
section "12. Restore browser profiles"
# =============================================================================

info "Restoring Firefox profile..."
if [ -d "$DOTFILES/.mozilla" ]; then
    cp -r "$DOTFILES/.mozilla" ~/
    info "Firefox profile restored."
else
    warn "No Firefox profile found in backup, skipping."
fi

info "Restoring LibreWolf profile..."
if [ -d "$DOTFILES/config/librewolf" ]; then
    mkdir -p ~/.config/librewolf
    cp -r "$DOTFILES/config/librewolf/." ~/.config/librewolf/
    info "LibreWolf profile restored."
else
    warn "No LibreWolf profile found in backup, skipping."
fi

# =============================================================================
section "13. Enable pipewire user services"
# =============================================================================

info "Enabling pipewire services..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber


# =============================================================================
section "DONE"
# =============================================================================

echo ""
echo -e "${BOLD}${GREEN}All done! A few manual steps remain:${RESET}"
echo ""
echo "  1. Go into BIOS and set primary display to PCIe/Discrete GPU"
echo "  2. Connect your monitor to the GTX 1050 Ti output"
echo "  3. Reboot"
echo "  4. After reboot, verify NVIDIA is active:  lspci | grep -i nvidia"
echo "  5. Log into TTY1 — Hyprland will auto-launch from .bash_profile"
echo ""
echo -e "${YELLOW}  If Hyprland fails to start, check:  journalctl --user -xe${RESET}"
echo ""
