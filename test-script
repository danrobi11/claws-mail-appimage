#!/bin/bash

# Script to build a portable Claws Mail AppImage with all dependencies and plugins
# Location: ~/.local/bin/claws-mail-appimage.sh
# Date: March 11, 2025
# Goal: Build on danrobi’s system, run on any Linux device

set -x  # Debug output
set -e  # Exit on error

USER_HOME="/home/danrobi"
VERSION="4.3.0"
WORKDIR="$USER_HOME/claws-mail-appimage-build"
INSTALL_DIR="$WORKDIR/install"
APPIMAGE_DIR="$WORKDIR/ClawsMail.AppDir"
SOURCE_URL="https://www.claws-mail.org/download.php?file=releases/claws-mail-${VERSION}.tar.xz"
APPIMAGETOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage"
LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"

# Ensure ~/.local/bin exists
mkdir -p "$USER_HOME/.local/bin"
chmod +x "$USER_HOME/.local/bin"

# Step 1: Install build tools and dependencies
echo "Installing build tools and dependencies..."
sudo apt update
sudo apt install -y \
    build-essential git curl wget pkg-config libgtk-3-dev libfuse2 \
    libetpan-dev libgnutls28-dev libgpgme-dev libenchant-2-dev \
    libpoppler-glib-dev libcanberra-dev libnotify-dev libperl-dev \
    python3-dev libytnef0-dev libical-dev libarchive-dev libldap2-dev \
    libcompfaceg1-dev libdb-dev libstartup-notification0-dev libx11-dev \
    libsm-dev libsoup2.4-dev libgumbo-dev libsecret-1-dev libjson-glib-dev \
    ghostscript spamassassin appstream || echo "Some optional deps failed."

# Try WebKitGTK 4.0 or 4.1 based on distro
if ! sudo apt install -y libwebkit2gtk-4.0-dev; then
    sudo apt install -y libwebkit2gtk-4.1-dev || echo "WebKitGTK skipped; Fancy plugin may not work."
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
    --enable-gtk3 --enable-libetpan --enable-gnutls --enable-pgp-core \
    --enable-pgp-inline --enable-pgp-mime --enable-enchant --enable-poppler \
    --enable-canberra --enable-notify --enable-perl --enable-python \
    --enable-tnef --enable-vcalendar --enable-ldap --enable-compface \
    --enable-dillo --enable-fancy --enable-rssyl --enable-spamassassin \
    --enable-bogofilter --enable-notification --enable-pdf-viewer \
    --enable-spam-report --enable-address-keeper --enable-acpi-notifier \
    --enable-maildir --enable-newmail --enable-managesieve || echo "Some plugins may be disabled."

# Step 5: Build and install to staging directory
echo "Building and installing Claws Mail..."
make -j$(nproc)
make install

# Step 6: Prepare AppImage structure
echo "Setting up AppImage directory structure..."
cd "$APPIMAGE_DIR"
mkdir -p usr/bin usr/lib usr/share/applications usr/share/icons/hicolor/48x48/apps usr/share/perl

# Copy Claws Mail binary
cp "$INSTALL_DIR/bin/claws-mail" usr/bin/

# Handle desktop file
if [ -f "$INSTALL_DIR/share/applications/claws-mail.desktop" ]; then
    cp "$INSTALL_DIR/share/applications/claws-mail.desktop" .
    sed -i 's/Exec=claws-mail %u/Exec=AppRun/' claws-mail.desktop
    cp claws-mail.desktop usr/share/applications/
else
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

# Handle icon
if [ -f "$INSTALL_DIR/share/icons/hicolor/48x48/apps/claws-mail.png" ]; then
    cp "$INSTALL_DIR/share/icons/hicolor/48x48/apps/claws-mail.png" claws-mail.png
    cp "$INSTALL_DIR/share/icons/hicolor/48x48/apps/claws-mail.png" usr/share/icons/hicolor/48x48/apps/
else
    wget -O claws-mail.png "https://www.claws-mail.org/images/claws-mail_icon_48.png"
    cp claws-mail.png usr/share/icons/hicolor/48x48/apps/
fi
chmod 644 claws-mail.png usr/share/icons/hicolor/48x48/apps/claws-mail.png

# Create AppRun
ln -sf usr/bin/claws-mail AppRun
chmod +x AppRun

# Step 7: Bundle external tools (for plugins)
echo "Bundling external tools (ghostscript, spamassassin, perl)..."
cp /usr/bin/gs usr/bin/  # Ghostscript for PDF viewer
cp /usr/bin/spamassassin usr/bin/  # SpamAssassin script
cp /usr/bin/perl usr/bin/  # Perl interpreter

# Bundle Perl libraries and modules
if [ -d "/usr/lib/x86_64-linux-gnu/perl" ]; then
    cp -r /usr/lib/x86_64-linux-gnu/perl usr/lib/
elif [ -d "/usr/lib/x86_64-linux-gnu/perl5" ]; then
    cp -r /usr/lib/x86_64-linux-gnu/perl5 usr/lib/
else
    echo "Warning: Perl libraries not found; SpamAssassin may not work."
fi
if [ -d "/usr/share/perl" ]; then
    cp -r /usr/share/perl/* usr/share/perl/
fi

# Step 8: Download tools
echo "Downloading linuxdeploy and appimagetool..."
cd "$WORKDIR"
wget "$LINUXDEPLOY_URL" -O "$WORKDIR/linuxdeploy.AppImage"
wget "$APPIMAGETOOL_URL" -O "$WORKDIR/appimagetool.AppImage"
if [ ! -f "$WORKDIR/linuxdeploy.AppImage" ]; then
    echo "Error: Failed to download linuxdeploy.AppImage"
    exit 1
fi
if [ ! -f "$WORKDIR/appimagetool.AppImage" ]; then
    echo "Error: Failed to download appimagetool.AppImage"
    exit 1
fi
chmod +x "$WORKDIR/linuxdeploy.AppImage" "$WORKDIR/appimagetool.AppImage"

# Step 9: Bundle dependencies with linuxdeploy and create AppImage
echo "Bundling dependencies with linuxdeploy..."
"$WORKDIR/linuxdeploy.AppImage" --appdir "$APPIMAGE_DIR" \
    --executable="$APPIMAGE_DIR/usr/bin/claws-mail" \
    --executable="$APPIMAGE_DIR/usr/bin/gs" \
    --executable="$APPIMAGE_DIR/usr/bin/perl" \
    --desktop-file="$APPIMAGE_DIR/claws-mail.desktop" \
    --icon-file="$APPIMAGE_DIR/claws-mail.png"

echo "Creating AppImage with appimagetool..."
"$WORKDIR/appimagetool.AppImage" "$APPIMAGE_DIR" "$WORKDIR/claws-mail-${VERSION}.AppImage"

# Step 10: Move and clean up
echo "Moving AppImage and cleaning up..."
if [ -f "$WORKDIR/claws-mail-${VERSION}.AppImage" ]; then
    mv "$WORKDIR/claws-mail-${VERSION}.AppImage" "$USER_HOME/.local/bin/claws-mail.AppImage"
    chmod +x "$USER_HOME/.local/bin/claws-mail.AppImage"
else
    echo "Error: AppImage not found at $WORKDIR/claws-mail-${VERSION}.AppImage"
    exit 1
fi
cd "$USER_HOME"
rm -rf "$WORKDIR" "$WORKDIR/linuxdeploy.AppImage" "$WORKDIR/appimagetool.AppImage"

echo "Done! Portable AppImage created at: ~/.local/bin/claws-mail.AppImage"
sha256sum "$USER_HOME/.local/bin/claws-mail.AppImage"
