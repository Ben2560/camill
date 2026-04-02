#!/bin/bash

# IPアドレスを確認・自動更新
CURRENT_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
CONSTANTS_FILES=(
  "/Users/tsutomuwatanabe/camill/lib/core/constants.dart"
  "/Users/tsutomuwatanabe/camill_admin/lib/core/constants.dart"
)

IP_CHANGED=false

if [ -z "$CURRENT_IP" ]; then
  echo "⚠️  IPアドレスを取得できませんでした。Wi-Fiに接続されていますか？"
else
  for FILE in "${CONSTANTS_FILES[@]}"; do
    SAVED_IP=$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$FILE" | head -1)
    if [ "$CURRENT_IP" = "$SAVED_IP" ]; then
      echo "✅ IP変更なし ($CURRENT_IP) → $(basename $(dirname $(dirname $(dirname $FILE))))"
    else
      sed -i '' "s|http://$SAVED_IP:8000|http://$CURRENT_IP:8000|g" "$FILE"
      echo "🔄 IP更新: $SAVED_IP → $CURRENT_IP ($(basename $(dirname $(dirname $(dirname $FILE)))))"
      IP_CHANGED=true
    fi
  done
fi

if [ "$IP_CHANGED" = true ]; then
  echo "🧹 IP変更を検知したため flutter clean && flutter pub get を実行します..."
  cd /Users/tsutomuwatanabe/camill
  flutter clean
  flutter pub get
fi

# iOSバージョンを確認・変化があれば pub get & pod install
IOS_VERSION_FILE="/Users/tsutomuwatanabe/camill/.ios_device_version"
CURRENT_IOS=$(xcrun xctrace list devices 2>/dev/null | grep -E "iPhone|iPad" | grep -v Simulator | head -1 | grep -oE '\([0-9]+\.[0-9]+(\.[0-9]+)?\)' | tr -d '()')

if [ -n "$CURRENT_IOS" ]; then
  SAVED_IOS=$(cat "$IOS_VERSION_FILE" 2>/dev/null)
  if [ "$CURRENT_IOS" != "$SAVED_IOS" ]; then
    echo "📱 iOSバージョン変更を検知: ${SAVED_IOS:-なし} → $CURRENT_IOS"
    echo "🔧 flutter pub get & pod install を実行します..."
    cd /Users/tsutomuwatanabe/camill
    flutter pub get
    cd ios && pod install --repo-update && cd ..
    echo "$CURRENT_IOS" > "$IOS_VERSION_FILE"
    echo "✅ 完了（バージョンを保存しました）"
  else
    echo "✅ iOSバージョン変更なし ($CURRENT_IOS)"
  fi
else
  echo "⚠️  iOSデバイスのバージョン取得できませんでした（デバイス未接続？）"
fi

# APIサーバーをバックグラウンドで起動
cd /Users/tsutomuwatanabe/camill-api
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000 --reload --log-level warning &
API_PID=$!

echo "APIサーバー起動中... (PID: $API_PID)"
sleep 2

# Flutterアプリを起動
cd /Users/tsutomuwatanabe/camill
flutter run --device-timeout 30 2> >(grep -Ev "maps to more than one section|Dart VM Service was not discovered" >&2)

# Flutter終了後にAPIも停止
echo "APIサーバーを停止します..."
kill $API_PID
