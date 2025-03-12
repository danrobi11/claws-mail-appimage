#!/bin/bash

# Script to build Claws Mail AppImage with all dependencies and plugins
# Location: ~/.local/bin/claws-mail-appimage.sh
# Date: March 11, 2025

# Enable debugging output
set -x

# Exit on any error (unless handled)
set -e

# Define variables using user's home
USER_HOME="/home/danrobi"
VERSION="4.3.0"
WORKDIR="$USER_HOME/claws-mail-appimage-build"
INSTALL_DIR="$WORKDIR/install"
APPIMAGE_DIR="$WORKDIR/ClawsMail.AppDir"
SOURCE_URL="https://www.claws-mail.org/download.php?file=releases/claws-mail-${VERSION}.tar.xz"
APPIMAGETOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage"

# Ensure ~/.local/bin exists and is executable
mkdir -p "$USER_HOME/.local/bin"
chmod +x "$USER_HOME/.local/bin"

# Step 1: Install build tools and dependencies
echo "Installing build tools and dependencies..."
sudo apt update
sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    pkg-config \
    libgtk-3-dev \
    libfuse2t64 \
    libetpan-dev \
    libgnutls28-dev \
    libgpgme-dev \
    libenchant-2-dev \
    libpoppler-glib-dev \
    libcanberra-dev \
    libnotify-dev \
    libperl-dev \
    python3-dev \
    libytnef0-dev \
    libical-dev \
    libarchive-dev \
    libldap2-dev \
    libcompfaceg1-dev \
    libdb-dev \
    libstartup-notification0-dev \
    libx11-dev \
    libsm-dev \
    libsoup2.4-dev \
    libgumbo-dev \
    libsecret-1-dev \
    libjson-glib-dev \
    ghostscript \
    spamassassin \
    appstream || echo "Some optional dependencies failed; continuing..."

# Try WebKitGTK variants
echo "Attempting to install WebKitGTK..."
if ! sudo apt install -y libwebkit2gtk-4.1-dev; then
    sudo apt install -y libwebkit2gtk-4.0-dev || echo "WebKitGTK not installed; Fancy plugin skipped."
fi

# Step 2: Set up working directory
echo "Setting up working directory: $WORKDIR"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR" "$INSTALL_DIR" "$APPIMAGE_DIR"
cd "$WORKDIR"

# Step 3: Download and extract Claws Mail source
echo "Downloading Claws Mail $VERSION..."
wget "$SOURCE_URL" -O "claws-mail-${VERSION}.tar.xz"
tar -xf "claws-mail-${VERSION}.tar.xz"
cd "claws-mail-${VERSION}"

# Step 4: Configure with all plugins
echo "Configuring Claws Mail with all plugins..."
./configure \
    --prefix="$INSTALL_DIR" \
    --enable-gtk3 \
    --enable-libetpan \
    --enable-gnutls \
    --enable-pgp-core \
    --enable-pgp-inline \
    --enable-pgp-mime \
    --enable-enchant \
    --enable-poppler \
    --enable-canberra \
    --enable-notify \
    --enable-perl \
    --enable-python \
    --enable-tnef \
    --enable-vcalendar \
    --enable-ldap \
    --enable-compface \
    --enable-dillo \
    --enable-fancy \
    --enable-rssyl \
    --enable-spamassassin \
    --enable-bogofilter \
    --enable-notification \
    --enable-pdf-viewer \
    --enable-spam-report \
    --enable-address-keeper \
    --enable-acpi-notifier \
    --enable-maildir \
    --enable-newmail \
    --enable-managesieve || echo "Some plugins may be disabled."

# Step 5: Build and install
echo "Building and installing Claws Mail..."
make -j$(nproc)
make install

# Step 6: Prepare AppImage structure
echo "Setting up AppImage directory structure..."
cd "$APPIMAGE_DIR"
mkdir -p usr/bin usr/lib usr/share/applications usr/share/icons/hicolor/48x48/apps
cp "$INSTALL_DIR/bin/claws-mail" usr/bin/
cp -r "$INSTALL_DIR/lib/"* usr/lib/
if [ -f "$INSTALL_DIR/share/applications/claws-mail.desktop" ]; then
    cp "$INSTALL_DIR/share/applications/claws-mail.desktop" .
    sed -i 's/Exec=claws-mail %u/Exec=AppRun/' claws-mail.desktop
    cp "$INSTALL_DIR/share/applications/claws-mail.desktop" usr/share/applications/
else
    echo "Creating basic desktop file..."
    cat <<EOF > claws-mail.desktop
[Desktop Entry]
Name=Claws Mail
Exec=AppRun
Type=Application
Icon=claws-mail
Categories=Network;Email;
Terminal=false
EOF
    cp claws-mail.desktop usr/share/applications/
fi
chmod 644 claws-mail.desktop usr/share/applications/claws-mail.desktop
if [ -f "$INSTALL_DIR/share/icons/hicolor/48x48/apps/claws-mail.png" ]; then
    cp "$INSTALL_DIR/share/icons/hicolor/48x48/apps/claws-mail.png" claws-mail.png
    cp "$INSTALL_DIR/share/icons/hicolor/48x48/apps/claws-mail.png" usr/share/icons/hicolor/48x48/apps/
fi
chmod 644 claws-mail.png usr/share/icons/hicolor/48x48/apps/claws-mail.png
ln -sf usr/bin/claws-mail AppRun
chmod +x AppRun
echo "Desktop file contents:"
cat claws-mail.desktop

# Step 7: Download appimagetool (stable v13)
echo "Downloading appimagetool..."
wget "$APPIMAGETOOL_URL" -O appimagetool.AppImage
chmod +x appimagetool.AppImage

# Step 8: Build the AppImage with detailed output
echo "Building Claws Mail AppImage..."
if ! ./appimagetool.AppImage "$APPIMAGE_DIR" "$USER_HOME/Claws-Mail-${VERSION}-x86_64.AppImage" 2>&1; then
    echo "AppImage build failed; AppDir contents:"
    ls -R "$APPIMAGE_DIR"
    exit 1
fi

# Step 9: Clean up
echo "Cleaning up..."
cd "$USER_HOME"
rm -rf "$WORKDIR" appimagetool.AppImage

# Step 10: Move to ~/.local/bin
echo "Moving AppImage to ~/.local/bin..."
mv "$USER_HOME/Claws-Mail-${VERSION}-x86_64.AppImage" "$USER_HOME/.local/bin/claws-mail.AppImage"
chmod +x "$USER_HOME/.local/bin/claws-mail.AppImage"

echo "Done! Run Claws Mail with: ~/.local/bin/claws-mail.AppImage"
