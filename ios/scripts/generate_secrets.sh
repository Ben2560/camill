#!/bin/bash
# secrets.properties → Secrets.xcconfig に変換
SECRETS_FILE="${SRCROOT}/../secrets.properties"
OUTPUT_FILE="${SRCROOT}/Flutter/Secrets.xcconfig"

echo "// Auto-generated from secrets.properties — do not commit" > "$OUTPUT_FILE"

if [ -f "$SECRETS_FILE" ]; then
  while IFS='=' read -r key value; do
    # 空行・コメント行をスキップ
    [[ -z "$key" || "$key" == \#* ]] && continue
    echo "$key = $value" >> "$OUTPUT_FILE"
  done < "$SECRETS_FILE"
fi
