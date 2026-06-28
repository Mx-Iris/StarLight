#!/usr/bin/env bash
#
# Build, sign, notarize, staple, and zip StarLight for distribution.
#
# Required env vars:
#   RELEASE_TAG                  e.g. v1.7. Used as the artifact name suffix.
#
# Signing (pick exactly one mode):
#   Mode A — CI / fresh keychain (default when MACOS_CERTIFICATE_BASE64 is set):
#     MACOS_CERTIFICATE_BASE64    Developer ID Application .p12, base64-encoded
#     MACOS_CERTIFICATE_PASSWORD  Password for the .p12
#     KEYCHAIN_PASSWORD           Password for the temporary keychain
#
#   Mode B — local / existing login keychain:
#     Leave MACOS_CERTIFICATE_BASE64 unset. The script will assume your
#     Developer ID Application identity is already imported into your login
#     keychain (the usual setup on a developer's Mac).
#
# Notarization (pick exactly one mode):
#   Mode A — API key (default when NOTARY_API_KEY_BASE64 is set):
#     NOTARY_API_KEY_BASE64       App Store Connect API .p8 key, base64-encoded
#     NOTARY_API_KEY_ID           Key ID (10 characters)
#     NOTARY_API_ISSUER_ID        Issuer UUID
#
#   Mode B — stored keychain profile:
#     NOTARY_KEYCHAIN_PROFILE     Name passed to `xcrun notarytool store-credentials`
#
# Optional env vars (with defaults):
#   WORKSPACE          StarLight.xcworkspace
#   SCHEME             StarLight
#   CONFIGURATION      Release
#   DEVELOPMENT_TEAM   D5Q73692VW
#   BUILD_DIR          build
#
set -euo pipefail

WORKSPACE="${WORKSPACE:-StarLight.xcworkspace}"
SCHEME="${SCHEME:-StarLight}"
CONFIGURATION="${CONFIGURATION:-Release}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-D5Q73692VW}"
BUILD_DIR="${BUILD_DIR:-build}"

ARCHIVE_PATH="$BUILD_DIR/StarLight.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"
DIST_PATH="$BUILD_DIR/dist"
EXPORT_OPTIONS_PATH="$BUILD_DIR/ExportOptions.plist"

if [ -z "${RELEASE_TAG:-}" ]; then
    echo "ERROR: RELEASE_TAG is required (e.g. v1.7)." >&2
    exit 1
fi

ASSET_NAME="StarLight-${RELEASE_TAG}.zip"

rm -rf "$BUILD_DIR"
mkdir -p "$EXPORT_PATH" "$DIST_PATH"

CERT_PATH=""
KEYCHAIN_PATH=""
API_KEY_PATH=""

cleanup() {
    [ -n "$CERT_PATH" ] && rm -f "$CERT_PATH"
    [ -n "$API_KEY_PATH" ] && rm -f "$API_KEY_PATH"
    if [ -n "$KEYCHAIN_PATH" ] && [ -f "$KEYCHAIN_PATH" ]; then
        security delete-keychain "$KEYCHAIN_PATH" 2>/dev/null || true
    fi
}
trap cleanup EXIT

#-------------------------------------------------------------------------------
# 1. Signing identity setup
#-------------------------------------------------------------------------------
SIGN_KEYCHAIN_ARGS=()

if [ -n "${MACOS_CERTIFICATE_BASE64:-}" ]; then
    : "${MACOS_CERTIFICATE_PASSWORD:?required when MACOS_CERTIFICATE_BASE64 is set}"
    : "${KEYCHAIN_PASSWORD:?required when MACOS_CERTIFICATE_BASE64 is set}"

    echo "==> Importing Developer ID Application certificate into a temp keychain"
    CERT_PATH="$(mktemp -t starlight-cert).p12"
    KEYCHAIN_PATH="${RUNNER_TEMP:-$BUILD_DIR}/starlight-release.keychain-db"

    printf '%s' "$MACOS_CERTIFICATE_BASE64" | base64 --decode > "$CERT_PATH"

    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

    security import "$CERT_PATH" \
        -P "$MACOS_CERTIFICATE_PASSWORD" \
        -A -t cert -f pkcs12 \
        -k "$KEYCHAIN_PATH"

    # Prepend the new keychain to the user search list so codesign can find it.
    ORIG_KEYCHAINS=$(security list-keychain -d user | sed -e 's/^ *//' -e 's/"//g' | tr '\n' ' ')
    # shellcheck disable=SC2086
    security list-keychain -d user -s "$KEYCHAIN_PATH" $ORIG_KEYCHAINS

    security set-key-partition-list \
        -S apple-tool:,apple:,codesign: \
        -s -k "$KEYCHAIN_PASSWORD" \
        "$KEYCHAIN_PATH" >/dev/null

    SIGN_KEYCHAIN_ARGS=(OTHER_CODE_SIGN_FLAGS="--keychain $KEYCHAIN_PATH")
else
    echo "==> MACOS_CERTIFICATE_BASE64 not set — assuming Developer ID identity is in the login keychain"
fi

#-------------------------------------------------------------------------------
# 2. Archive with manual signing
#-------------------------------------------------------------------------------
echo "==> Resolving SPM dependencies"
xcodebuild \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -resolvePackageDependencies

echo "==> Archiving"
xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    "${SIGN_KEYCHAIN_ARGS[@]}"

#-------------------------------------------------------------------------------
# 3. Export as Developer ID
#-------------------------------------------------------------------------------
cat > "$EXPORT_OPTIONS_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>teamID</key>
    <string>$DEVELOPMENT_TEAM</string>
</dict>
</plist>
EOF

echo "==> Exporting archive"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PATH"

APP_PATH="$EXPORT_PATH/StarLight.app"
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: Exported $APP_PATH not found." >&2
    exit 1
fi

#-------------------------------------------------------------------------------
# 4. Notarize and staple
#-------------------------------------------------------------------------------
NOTARY_ARGS=()
if [ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]; then
    NOTARY_ARGS=(--keychain-profile "$NOTARY_KEYCHAIN_PROFILE")
elif [ -n "${NOTARY_API_KEY_BASE64:-}" ]; then
    : "${NOTARY_API_KEY_ID:?required when NOTARY_API_KEY_BASE64 is set}"
    : "${NOTARY_API_ISSUER_ID:?required when NOTARY_API_KEY_BASE64 is set}"
    API_KEY_PATH="$(mktemp -t starlight-notary).p8"
    printf '%s' "$NOTARY_API_KEY_BASE64" | base64 --decode > "$API_KEY_PATH"
    NOTARY_ARGS=(
        --key "$API_KEY_PATH"
        --key-id "$NOTARY_API_KEY_ID"
        --issuer "$NOTARY_API_ISSUER_ID"
    )
else
    echo "ERROR: No notarization credentials. Set NOTARY_API_KEY_BASE64 + NOTARY_API_KEY_ID + NOTARY_API_ISSUER_ID, or NOTARY_KEYCHAIN_PROFILE." >&2
    exit 1
fi

NOTARIZE_ZIP="$BUILD_DIR/StarLight.notarize.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$NOTARIZE_ZIP"

echo "==> Submitting for notarization (this can take several minutes)"
xcrun notarytool submit "$NOTARIZE_ZIP" "${NOTARY_ARGS[@]}" --wait

rm -f "$NOTARIZE_ZIP"

echo "==> Stapling notarization ticket"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

#-------------------------------------------------------------------------------
# 5. Package the final distribution zip
#-------------------------------------------------------------------------------
ASSET_PATH="$DIST_PATH/$ASSET_NAME"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ASSET_PATH"

echo
echo "==> Built successfully"
echo "    $ASSET_PATH"
shasum -a 256 "$ASSET_PATH"
