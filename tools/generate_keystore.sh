#!/usr/bin/env bash
# Generates a NEW release keystore for TraderLog and prints the values to put
# in GitHub Secrets. Run this on your own machine - the passwords are created
# locally and never need to be pasted anywhere except GitHub Secrets.
#
# Usage:  bash tools/generate_keystore.sh [output_dir]
set -euo pipefail

OUT_DIR="${1:-$HOME/traderlog-signing}"
KEYSTORE="$OUT_DIR/traderlog-release.jks"
ALIAS="traderlog"

command -v keytool >/dev/null || { echo "keytool not found (install a JDK 17)"; exit 1; }
[ -e "$KEYSTORE" ] && { echo "Refusing to overwrite existing $KEYSTORE"; exit 1; }

mkdir -p "$OUT_DIR"
chmod 700 "$OUT_DIR"

# Strong random password (alphanumeric only, so it is safe in shells / YAML).
PASS="$(head -c 256 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | cut -c1-28)"
[ "${#PASS}" -ge 24 ] || { echo "Could not generate a strong password"; exit 1; }

keytool -genkeypair -v \
  -keystore "$KEYSTORE" \
  -storetype PKCS12 \
  -alias "$ALIAS" \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -storepass "$PASS" -keypass "$PASS" \
  -dname "CN=TraderLog, O=TraderLog, C=ID"

chmod 600 "$KEYSTORE"

# Local-build helper (git-ignored): android/key.properties
cat > "$OUT_DIR/key.properties" <<PROPS
storeFile=$KEYSTORE
storePassword=$PASS
keyAlias=$ALIAS
keyPassword=$PASS
PROPS
chmod 600 "$OUT_DIR/key.properties"

cat <<MSG

================ KEYSTORE CREATED ================
File : $KEYSTORE

1) BACK IT UP NOW (password manager + offline copy).
   If you lose this file or the password you can never update the app
   for existing users again.

2) Add these four GitHub Secrets
   (Repo -> Settings -> Secrets and variables -> Actions):

   TRADERLOG_KEYSTORE_BASE64   = $(base64 -w0 "$KEYSTORE" 2>/dev/null || base64 "$KEYSTORE" | tr -d '\n')
   TRADERLOG_KEYSTORE_PASSWORD = $PASS
   TRADERLOG_KEY_ALIAS         = $ALIAS
   TRADERLOG_KEY_PASSWORD      = $PASS

3) For local release builds copy:
   cp "$OUT_DIR/key.properties" android/key.properties

4) Clear your terminal history / scrollback - the password was printed above.
==================================================
MSG
