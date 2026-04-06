#!/bin/bash

# Check and auto-update IP address
CURRENT_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
CONSTANTS_FILES=(
  "/Users/tsutomuwatanabe/camill/lib/core/constants.dart"
  "/Users/tsutomuwatanabe/camill_admin/lib/core/constants.dart"
)

IP_CHANGED=false

if [ -z "$CURRENT_IP" ]; then
  echo "⚠️  Could not retrieve IP address. Are you connected to Wi-Fi?"
else
  for FILE in "${CONSTANTS_FILES[@]}"; do
    SAVED_IP=$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$FILE" | head -1)
    if [ "$CURRENT_IP" = "$SAVED_IP" ]; then
      echo "✅ IP unchanged ($CURRENT_IP) → $(basename $(dirname $(dirname $(dirname $FILE))))"
    else
      sed -i '' "s|http://$SAVED_IP:8000|http://$CURRENT_IP:8000|g" "$FILE"
      echo "🔄 IP updated: $SAVED_IP → $CURRENT_IP ($(basename $(dirname $(dirname $(dirname $FILE)))))"
      IP_CHANGED=true
    fi
  done
fi

if [ "$IP_CHANGED" = true ]; then
  echo "🧹 IP change detected. Running flutter clean && flutter pub get..."
  cd /Users/tsutomuwatanabe/camill
  flutter clean
  flutter pub get
fi

# Check iOS version; run pub get & pod install if changed
IOS_VERSION_FILE="/Users/tsutomuwatanabe/camill/.ios_device_version"
CURRENT_IOS=$(xcrun xctrace list devices 2>/dev/null | grep -E "iPhone|iPad" | grep -v Simulator | head -1 | grep -oE '\([0-9]+\.[0-9]+(\.[0-9]+)?\)' | tr -d '()')

if [ -n "$CURRENT_IOS" ]; then
  SAVED_IOS=$(cat "$IOS_VERSION_FILE" 2>/dev/null)
  if [ "$CURRENT_IOS" != "$SAVED_IOS" ]; then
    echo "📱 iOS version change detected: ${SAVED_IOS:-none} → $CURRENT_IOS"
    echo "🔧 Running flutter pub get & pod install..."
    cd /Users/tsutomuwatanabe/camill
    flutter pub get
    cd ios && pod install --repo-update && cd ..
    echo "$CURRENT_IOS" > "$IOS_VERSION_FILE"
    echo "✅ Done (version saved)"
  else
    echo "✅ iOS version unchanged ($CURRENT_IOS)"
  fi
else
  echo "⚠️  Could not retrieve iOS device version (device not connected?)"
fi

# Start API server in background
cd /Users/tsutomuwatanabe/camill-api
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000 --reload --log-level warning &
API_PID=$!

echo "Starting API server... (PID: $API_PID)"
sleep 2

# Start Flutter app
cd /Users/tsutomuwatanabe/camill
flutter run --device-timeout 30 2> >(grep -Ev "maps to more than one section|Dart VM Service was not discovered" >&2)

# Stop API server after Flutter exits
echo "Stopping API server..."
kill $API_PID
