#!/bin/bash
# setup-mas-certs.sh
#
# Generates Mac App Store signing certificates and exports them as a P12
# ready to paste into GitHub Secrets.
#
# Usage:
#   ./setup-mas-certs.sh
#
# What it does:
#   1. Generate a CSR (Certificate Signing Request)
#   2. Create "Mac App Distribution" cert via `asc`
#   3. Open Apple Developer portal for "Mac Installer Distribution" cert
#   4. Install both certs in your keychain
#   5. Export as P12 → print base64 for GitHub Secrets
#
# Prerequisites:
#   brew install asccli        (or asc auth login already done)
#   asc auth check             (credentials must be configured)

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

step()  { echo -e "\n${BOLD}${BLUE}▶ $*${NC}"; }
ok()    { echo -e "${GREEN}✓ $*${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $*${NC}"; }
die()   { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }
pause() { echo -e "\n${YELLOW}Press Enter when done...${NC}"; read -r; }

# ── Workdir ───────────────────────────────────────────────────────────────────
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
CSR_PATH="$WORKDIR/mac-distribution.csr"
KEY_PATH="$WORKDIR/mac-distribution.key"
APP_CERT_PATH="$WORKDIR/mac-app-dist.cer"
INSTALLER_CERT_PATH="$WORKDIR/mac-installer-dist.cer"
P12_PATH="$HOME/Desktop/APPLE_MAS_CERTIFICATE.p12"

# ── Prerequisites ─────────────────────────────────────────────────────────────
step "Checking prerequisites"

command -v asc  >/dev/null 2>&1 || die "'asc' not found. Run: brew tap tddworks/tap && brew install asccli"
command -v jq   >/dev/null 2>&1 || die "'jq' not found. Run: brew install jq"
command -v openssl >/dev/null 2>&1 || die "'openssl' not found."

asc auth check >/dev/null 2>&1 || die "asc credentials not set up. Run: asc auth login --key-id <id> --issuer-id <id> --private-key-path <path>"
ok "Prerequisites met"

# ── CSR ───────────────────────────────────────────────────────────────────────
step "Generating Certificate Signing Request (CSR)"

echo -n "Your name (for the certificate): "
read -r CERT_NAME
echo -n "Your email: "
read -r CERT_EMAIL

openssl req -nodes -newkey rsa:2048 \
  -keyout "$KEY_PATH" \
  -out "$CSR_PATH" \
  -subj "/emailAddress=${CERT_EMAIL}/CN=${CERT_NAME}/C=US" \
  2>/dev/null

ok "CSR generated at $CSR_PATH"

# ── Mac App Distribution cert (via asc) ───────────────────────────────────────
step "Creating Mac App Distribution certificate via asc"
echo "  (This is the '3rd Party Mac Developer Application' cert that signs your .app)"

CERT_RESPONSE=$(asc certificates create \
  --type MAC_APP_DISTRIBUTION \
  --csr-path "$CSR_PATH")

CERT_CONTENT=$(echo "$CERT_RESPONSE" | jq -r '.data[0].certificateContent // empty')

if [ -z "$CERT_CONTENT" ]; then
  die "Failed to create MAC_APP_DISTRIBUTION certificate. Check: asc certificates list --type MAC_APP_DISTRIBUTION"
fi

echo "$CERT_CONTENT" | base64 --decode > "$APP_CERT_PATH"
security import "$APP_CERT_PATH" -k ~/Library/Keychains/login.keychain-db 2>/dev/null || \
security import "$APP_CERT_PATH" 2>/dev/null || true
ok "Mac App Distribution cert created and installed"

# ── Mac Installer Distribution cert (via portal) ──────────────────────────────
step "Creating Mac Installer Distribution certificate (Apple Developer Portal)"
echo "  (This is the '3rd Party Mac Developer Installer' cert that signs your .pkg)"
echo ""
echo "  The Apple API doesn't support creating this cert type programmatically."
echo "  Please do this manually:"
echo ""
echo "  1. Opening Apple Developer Certificates page..."
sleep 1
open "https://developer.apple.com/account/resources/certificates/add"
echo ""
echo "  2. Select: Mac Installer Distribution"
echo "  3. Upload this CSR file: $CSR_PATH"
echo "     (drag it to Finder: $(dirname "$CSR_PATH"))"
echo "  4. Download the generated .cer file"
echo "  5. Move it here: $INSTALLER_CERT_PATH"
echo "     mv ~/Downloads/mac_installer.cer $INSTALLER_CERT_PATH"

pause

if [ ! -f "$INSTALLER_CERT_PATH" ]; then
  warn "Installer cert not found at $INSTALLER_CERT_PATH"
  echo -n "Enter the path to the downloaded .cer file: "
  read -r USER_CERT_PATH
  cp "$USER_CERT_PATH" "$INSTALLER_CERT_PATH"
fi

security import "$INSTALLER_CERT_PATH" -k ~/Library/Keychains/login.keychain-db 2>/dev/null || \
security import "$INSTALLER_CERT_PATH" 2>/dev/null || true
ok "Mac Installer Distribution cert installed"

# ── Export P12 ────────────────────────────────────────────────────────────────
step "Exporting both certificates as P12"
echo ""
echo "  Keychain Access will open. Please:"
echo "  1. Search for '3rd Party Mac Developer'"
echo "  2. Select BOTH items that show a private key arrow (▶)"
echo "     - 3rd Party Mac Developer Application: ${CERT_NAME}"
echo "     - 3rd Party Mac Developer Installer: ${CERT_NAME}"
echo "  3. Right-click → Export 2 Items"
echo "  4. Save as: $P12_PATH"
echo "  5. Set a password (you'll need it for APPLE_MAS_CERTIFICATE_PASSWORD)"
echo ""

open -a "Keychain Access"
pause

if [ ! -f "$P12_PATH" ]; then
  warn "P12 not found at $P12_PATH"
  echo -n "Enter the path to the exported .p12 file: "
  read -r USER_P12_PATH
  cp "$USER_P12_PATH" "$P12_PATH"
fi

# Verify the P12 is readable
echo -n "Enter the P12 password to verify: "
read -rs P12_PASSWORD
echo ""

if ! openssl pkcs12 -in "$P12_PATH" -passin "pass:$P12_PASSWORD" -noout 2>/dev/null; then
  if ! openssl pkcs12 -in "$P12_PATH" -passin "pass:$P12_PASSWORD" -legacy -noout 2>/dev/null; then
    die "Could not read P12 with that password. Try again."
  fi
fi
ok "P12 verified"

# ── Output GitHub Secrets ─────────────────────────────────────────────────────
step "GitHub Secrets values"
echo ""
echo "  Add these to your repo: Settings → Secrets and variables → Actions"
echo ""
echo -e "  ${BOLD}APPLE_MAS_CERTIFICATE_P12${NC}"
echo "  ─────────────────────────────────────────────────────"
base64 -i "$P12_PATH"
echo ""
echo -e "  ${BOLD}APPLE_MAS_CERTIFICATE_PASSWORD${NC}"
echo "  ─────────────────────────────────────────────────────"
echo "  $P12_PASSWORD"
echo ""
ok "Done! P12 also saved to: $P12_PATH (keep it safe)"
