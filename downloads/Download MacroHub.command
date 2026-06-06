#!/bin/zsh
set -e

cd "$(dirname "$0")"

ANSWER="$(osascript -e 'button returned of (display dialog "Download and install MacroHub? This replaces the old installed MacroHub app so files do not stack." buttons {"Cancel", "Download MacroHub"} default button "Download MacroHub" cancel button "Cancel" with title "MacroHub")' 2>/dev/null || true)"

if [[ "$ANSWER" != "Download MacroHub" ]]; then
  exit 0
fi

clear
echo "MacroHub Downloader"
echo "==================="
echo

ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  COMPUTER_TYPE="Apple Silicon Mac"
  NODE_HINT="macOS Installer (.pkg) for ARM64"
elif [[ "$ARCH" == "x86_64" ]]; then
  COMPUTER_TYPE="Intel Mac"
  NODE_HINT="macOS Installer (.pkg) for x64"
else
  COMPUTER_TYPE="Mac ($ARCH)"
  NODE_HINT="macOS Installer (.pkg) that matches $ARCH"
fi

echo "Computer detected: $COMPUTER_TYPE"
echo "Required: Node.js with npm"
echo "Official download: https://nodejs.org/en/download"
echo

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "Node.js is required before MacroHub can be installed."
  echo "Choose: $NODE_HINT"
  open "https://nodejs.org/en/download"
  read -k 1 "?Install Node.js, then run this again. Press any key to close."
  exit 1
fi

echo "Node.js installed: $(node --version)"
echo "npm installed: $(npm --version)"
echo

echo "Installing dependencies..."
npm_config_cache="/private/tmp/macrohub-npm-cache" npm install

echo
echo "Building MacroHub..."
rm -rf dist
export CSC_IDENTITY_AUTO_DISCOVERY=false
npm run package:mac -- --publish never

APP_PATH="$(find dist -name 'MacroHub.app' -maxdepth 3 -type d | head -n 1)"
if [[ -z "$APP_PATH" ]]; then
  echo "MacroHub was built, but MacroHub.app was not found in dist."
  open dist
  read -k 1 "?Press any key to close."
  exit 1
fi

echo
echo "Closing any running MacroHub..."
osascript -e 'tell application "MacroHub" to quit' >/dev/null 2>&1 || true
pkill -x "MacroHub" >/dev/null 2>&1 || true
sleep 1

echo "Replacing old app in Applications..."
find "/Applications" -maxdepth 1 -name "MacroHub*.app" ! -name "MacroHub Developer.app" -exec rm -rf {} + 2>/dev/null || true
cp -R "$APP_PATH" "/Applications/MacroHub.app"

echo "Cleaning MacroHub-only temporary files..."
rm -rf dist node_modules
PARENT_DIR="$(dirname "$PWD")"
find "$PARENT_DIR" -maxdepth 1 \( -name "MacroHub*.zip" -o -name "MacroHubDeveloper*.zip" \) -delete 2>/dev/null || true

echo "Opening MacroHub..."
open "/Applications/MacroHub.app"
read -k 1 "?MacroHub is installed. Press any key to close."
