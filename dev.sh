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
