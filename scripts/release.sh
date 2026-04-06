#!/bin/bash
set -euo pipefail

VERSION="${1:?Usage: release.sh <version> [build-number]}"
BUILD="${2:-$(date +%Y%m%d%H%M)}"
SCHEME="bnotch"
PROJECT="bnotch.xcodeproj"
ARCHIVE_PATH="build/bnotch.xcarchive"
EXPORT_DIR="build/export"
APP_NAME="bnotch.app"
ZIP_NAME="bnotch-${VERSION}.zip"
SIGNING_IDENTITY="Developer ID Application: Maik Klotz (FTJLR8JRNS)"
TEAM_ID="FTJLR8JRNS"

echo "==> Building archive for v${VERSION} (build ${BUILD})..."
mkdir -p build

xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD" \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="$TEAM_ID"

echo "==> Exporting app..."
cat > build/ExportOptions.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
    <key>teamID</key>
    <string>FTJLR8JRNS</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist build/ExportOptions.plist \
    -exportPath "$EXPORT_DIR"

echo "==> Notarizing..."
xcrun notarytool submit "${EXPORT_DIR}/${APP_NAME}" \
    --keychain-profile "simplebanking-notary" \
    --wait

xcrun stapler staple "${EXPORT_DIR}/${APP_NAME}"

echo "==> Creating ZIP for Sparkle..."
cd "$EXPORT_DIR"
ditto -c -k --keepParent "$APP_NAME" "../${ZIP_NAME}"
cd -

echo "==> Generating appcast..."
SPARKLE_BIN=$(find ~/Library/Developer/Xcode/DerivedData -path "*/SourcePackages/artifacts/sparkle/Sparkle/bin" -type d 2>/dev/null | head -1)

if [ -z "$SPARKLE_BIN" ]; then
    echo "ERROR: Sparkle binaries not found. Build the project in Xcode first."
    exit 1
fi

mkdir -p build/releases
cp "build/${ZIP_NAME}" build/releases/

"$SPARKLE_BIN/generate_appcast" build/releases/ \
    -o appcast.xml

echo ""
echo "==> Done! appcast.xml updated."
echo ""
echo "Next steps:"
echo "  1. git add appcast.xml && git commit -m 'Release v${VERSION}'"
echo "  2. git push"
echo "  3. gh release create v${VERSION} build/${ZIP_NAME} --title 'v${VERSION}'"
