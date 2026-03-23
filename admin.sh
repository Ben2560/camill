#!/bin/bash

# IPアドレスを確認・自動更新
CURRENT_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
CONSTANTS_FILES=(
  "/Users/tsutomuwatanabe/camill/lib/core/constants.dart"
  "/Users/tsutomuwatanabe/camill_admin/lib/core/constants.dart"
)

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
    fi
  done
fi

# APIサーバーをバックグラウンドで起動（まだ起動していない場合のみ）
if ! lsof -i :8000 > /dev/null 2>&1; then
  cd /Users/tsutomuwatanabe/camill-api
  source venv/bin/activate
  uvicorn main:app --host 0.0.0.0 --port 8000 --reload --log-level warning &
  API_PID=$!
  echo "APIサーバー起動中... (PID: $API_PID)"
  sleep 2
else
  echo "APIサーバーはすでに起動中です"
  API_PID=""
fi

# 管理アプリをiOSで起動
cd /Users/tsutomuwatanabe/camill_admin
flutter run

# 終了後にAPIも停止（このスクリプトが起動した場合のみ）
if [ -n "$API_PID" ]; then
  echo "APIサーバーを停止します..."
  kill $API_PID
fi
